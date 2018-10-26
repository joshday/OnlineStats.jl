
#-----------------------------------------------------------------------# Kahan Sum
"""
    KahanSum(T::Type = Float64)

Track the overall sum.

# Example

    fit!(KahanSum(Float64), fill(1, 100))
"""
mutable struct KahanSum{T<:Number} <: OnlineStat{Number}
    sum::T
    c::T
    n::Int
end
KahanSum(T::Type = Float64) = KahanSum(T(0), T(0), 0)
Base.sum(o::KahanSum) = o.sum
function _fit!(o::KahanSum{T}, x::Number) where {T<:Number}
    y = convert(T, x) - o.c
    t = o.sum + y
    o.c = (t - o.sum) - y
    o.sum = t
    o.n += 1
end
_merge!(o::T, o2::T) where {T <: KahanSum} = (o.sum += o2.sum; o.c += o2.c; o.n += o2.n; o)

#-----------------------------------------------------------------------# KahanMean
"""
    KahanMean(; T=Float64, weight=EqualWeight())

Track a univariate mean.

# Update

``μ = (1 - γ) * μ + γ * x``

# Example

    @time fit!(KahanMean(), randn(10^6))
"""
mutable struct KahanMean{W, T<:Number} <: OnlineStat{Number}
    μ::T
    c::T
    weight::W
    n::Int
end
KahanMean(;T::Type = Float64, weight = EqualWeight()) = KahanMean(0.0, 0.0, weight, 0)
function _fit!(o::KahanMean{W, T}, x) where {W, T}
    o.n += 1

    y = T(o.weight(o.n)) * (convert(T, x) - o.μ) - o.c
    t = o.μ + y
    o.c = (t - o.μ) - y
    o.μ = t
end
function _merge!(o::KahanMean, o2::KahanMean)
    o.n += o2.n
    o.μ = smooth(o.μ, o2.μ, o2.n / o.n)
    o.c += o2.c
end
Statistics.mean(o::KahanMean) = o.μ
Base.copy(o::KahanMean) = KahanMean(o.μ, o.c, o.weight, o.n)

#-----------------------------------------------------------------------# KahanVariance
"""
    KahanVariance(; T=Float64, weight=EqualWeight())

Univariate variance.

# Example

    o = fit!(KahanVariance(), randn(10^6))
    mean(o)
    var(o)
    std(o)
"""
mutable struct KahanVariance{W, T<:Number} <: OnlineStat{Number}
    σ2::T
    μ::T
    cμ::T
    cσ2::T
    weight::W
    n::Int
end
KahanVariance(;T::Type = Float64, weight = EqualWeight()) = KahanVariance(T(0.0), T(0.0), T(0.0), T(0.0), weight, 0)
Base.copy(o::KahanVariance) = KahanVariance(o.σ2, o.μ, o.weight, o.n)
function _fit!(o::KahanVariance{W, T}, x) where {W, T}

    xx = convert(T, x)
    o.n += 1
    γ = T(o.weight(o.n))
    μ = o.μ

    # o.μ = μ + γ * (xx - μ)
    y = γ * (xx - μ) - o.cμ
    t = μ + y
    o.cμ = (t - μ) - y
    o.μ = t

    # o.σ2 = o.σ2 + γ * ((xx - μ) * (xx - o.μ) - o.σ2)
    y = γ * ((xx - μ) * (xx - o.μ) - o.σ2) - o.cσ2
    t = o.σ2 + y
    o.cσ2 = (t - o.σ2) - y
    o.σ2 = t

    return nothing
end
function _merge!(o::KahanVariance, o2::KahanVariance)
    γ = o2.n / (o.n += o2.n)
    δ = o2.μ - o.μ
    o.σ2 = smooth(o.σ2, o2.σ2, γ) + δ ^ 2 * γ * (1.0 - γ)
    o.μ = smooth(o.μ, o2.μ, γ)
    o.cμ += o2.cμ
    o.cσ2 += o2.cσ2
    o
end
value(o::KahanVariance{W, T}) where {W, T} =
    o.n > 1 ? o.σ2 * unbias(o) : T(1.0)
Statistics.var(o::KahanVariance) = value(o)
Statistics.mean(o::KahanVariance) = o.μ
