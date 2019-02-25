
#-----------------------------------------------------------------------# Kahan Sum
"""
    KahanSum(T::Type = Float64)

Track the overall sum. Includes a compensation term that effectively doubles
precision, see
[Wikipedia](https://en.wikipedia.org/wiki/Kahan_summation_algorithm) for
details.

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

function _merge!(o::T, o2::T) where {T <: KahanSum}
    # correct both sums symmetrically if o and o2 are of different magnitude,
    # the correction factor of the smaller one will be lost.
    y = o2.sum - o.c
    y2 = o.sum - o2.c

    t = y2 + y

    # Here we find the case improved by Neumaier upon Kahan's algorithm, i.e. the
    # number added is orders of magnitude larger than the sum.
    if abs(y) < abs(y2)
        o.c = (t - y2) - y
    else
        o.c = (t - y) - y2
    end

    o.sum = t
    o.n += o2.n
    o
end

#-----------------------------------------------------------------------# KahanMean
"""
    KahanMean(; T=Float64, weight=EqualWeight())

Track a univariate mean. Uses a compensation term for the update.

#Note

This should be more accurate as [`Mean`](@ref) in most cases but the guarantees
of [`KahanSum`](@ref) do not apply. [`merge!`](@ref) can have some accuracy
issues.

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
KahanMean(T::Type) = KahanMean(T(0), T(0), EqualWeight(), 0)
KahanMean(;T::Type = Float64, weight = EqualWeight()) = KahanMean(T(0.0), T(0.0), weight, 0)
function _fit!(o::KahanMean{W, T}, x) where {W, T}
    o.n += 1

    # This acts under the assumption that the mean and all values are
    # approximately of the same order
    # o.μ = o.μ + T(o.weight(o.n)) * (convert(T, x) - o.μ) - o.c
    y = T(o.weight(o.n)) * (convert(T, x) - o.μ) - o.c
    t = o.μ + y
    o.c = (t - o.μ) - y
    o.μ = t
end
function _merge!(o::KahanMean{W1, T}, o2::KahanMean{W2, T}) where {W1, W2, T}

    o.n += o2.n
    # y = (T(o2.n / o.n) * (o2.μ - o.μ) - o.c) - o2.c
    x1 = o.μ - o2.c
    y = T(o2.n / o.n) * (o2.μ - x1) - o.c
    t = x1 + y

    if abs(x1) < abs(y)
        o.c = (t - y) - x1
    else
        o.c = (t - x1) - y
    end

    o.μ = t

    o
end
Statistics.mean(o::KahanMean) = o.μ
Base.copy(o::KahanMean) = KahanMean(o.μ, o.c, o.weight, o.n)

#-----------------------------------------------------------------------# KahanVariance
"""
    KahanVariance(; T=Float64, weight=EqualWeight())

Track the univariate variance. Uses compensation terms for a higher accuracy.

#Note

This should be more accurate as [`Variance`](@ref) in most cases but the
guarantees of [`KahanSum`](@ref) do not apply. [`merge!`](@ref) can have
accuracy issues.

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
KahanVariance(T::Type) =
    KahanVariance(T(0.0), T(0.0), T(0.0), T(0.0), EqualWeight(), 0)
KahanVariance(;T::Type = Float64, weight = EqualWeight()) =
    KahanVariance(T(0.0), T(0.0), T(0.0), T(0.0), weight, 0)
Base.copy(o::KahanVariance) =
    KahanVariance(o.σ2, o.μ, o.cμ, o.cσ2, o.weight, o.n)
function _fit!(o::KahanVariance{W, T}, x) where {W, T}

    o.n += 1
    γ = T(o.weight(o.n))
    μ = o.μ

    xx = convert(T, x)
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
function _merge!(o::KahanVariance{W1, T}, o2::KahanVariance{W2, T}) where {W1, W2, T}
    o.n += o2.n

    γ = T(o2.n / o.n)

    μ1 = o.μ - o2.cμ
    μ2 = o2.μ - o.cμ
    # Δμ = μ2 - μ1
    Δμ = μ2 - o.μ

    σ1 = o.σ2 - o2.cσ2
    σ2 = o2.σ2 - o.cσ2
    # Δσ = σ2 - σ1
    Δσ = σ2 - o.σ2

    # o.σ2 = γ * (o2.σ2 - o.σ2) + δ ^ 2 * γ * (1.0 - γ)
    # xx = (γ * Δσ) + ((Δμ ^ 2) * γ * (T(1.0) - γ))
    xx = γ * (Δσ + (Δμ ^ 2) * (T(1.0) - γ))
    y = xx - o.cσ2
    t = o.σ2 + y

    if abs(σ1) < abs(y)
        o.cσ2 = (t - y) - σ1
    else
        o.cσ2 = (t - σ1)  - y
    end

    o.σ2 = t

    # o.μ = o.μ + γ * (o2.μ - o.μ)
    # xx = γ * δ
    xx = γ * Δμ
    y = xx - o.cμ
    t = o.μ + y

    if abs(μ1) < abs(y)
        o.cμ = (t - y) - μ1
    else
        o.cμ = (t - μ1) - y
    end

    o.μ = t

    o
end
value(o::KahanVariance{W, T}) where {W, T} =
    o.n > 1 ? o.σ2 * bessel(o) : T(1.0)
Statistics.var(o::KahanVariance) = value(o)
Statistics.mean(o::KahanVariance) = o.μ
