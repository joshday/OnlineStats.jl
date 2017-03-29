#--------------------------------------------------------------------# Mean
"""
Univariate Mean

    s = Series(randn(100), Mean())
"""
mutable struct Mean <: OnlineStat{0, 0}
    μ::Float64
    Mean() = new(0.0)
end
fit!(o::Mean, y::Real, γ::Float64) = (o.μ = smooth(o.μ, y, γ))
fitbatch!(o::Mean, y::AVec, γ::Float64) = (o.μ = smooth(o.μ, mean(y), γ))
Base.merge!(o::Mean, o2::Mean, γ::Float64) = fit!(o, value(o2), γ)
Base.mean(o::Mean) = o.μ

#--------------------------------------------------------------------# Variance
"""
Univariate Variance

    s = Series(randn(100), Variance())
"""
mutable struct Variance <: OnlineStat{0, 0}
    σ2::Float64     # biased variance
    μ::Float64
    nobs::Int
    Variance() = new(0.0, 0.0, 0)
end
fields_to_show(o::Variance) = [:σ2, :μ]
function fit!(o::Variance, y::Real, γ::Float64)
    μ = o.μ
    o.nobs += 1
    o.μ = smooth(o.μ, y, γ)
    o.σ2 = smooth(o.σ2, (y - o.μ) * (y - μ), γ)
end
function Base.merge!(o::Variance, o2::Variance, γ::Float64)
    o.nobs += o2.nobs
    δ = o2.μ - o.μ
    o.σ2 = smooth(o.σ2, o2.σ2, γ) + δ ^ 2 * γ * (1.0 - γ)
    o.μ = smooth(o.μ, o2.μ, γ)
    o
end
value(o::Variance) = o.σ2 * unbias(o)
Base.var(o::Variance) = value(o)
Base.std(o::Variance) = sqrt(var(o))
Base.mean(o::Variance) = o.μ
nobs(o::Variance) = o.nobs

#--------------------------------------------------------------------# Extrema
"""
Maximum and minimum

    s = Series(randn(100), Extrema())
"""
mutable struct Extrema <: OnlineStat{0, 1}
    min::Float64
    max::Float64
    Extrema() = new(Inf, -Inf)
end
function fit!(o::Extrema, y::Real, γ::Float64)
    o.min = min(o.min, y)
    o.max = max(o.max, y)
    o
end
value(o::Extrema) = (o.min, o.max)

#--------------------------------------------------------------------# OrderStats
"""
Mean of order statistics for batches of size `b`

    b = 5
    s = Series(randn(100), OrderStats(b))
"""
mutable struct OrderStats <: OnlineStat{0, 1}
    value::VecF
    buffer::VecF
    i::Int
    nreps::Int
    OrderStats(p::Integer) = new(zeros(p), zeros(p), 0, 0)
end
function fit!(o::OrderStats, y::Real, γ::Float64)
    p = length(o.value)
    buffer = o.buffer
    o.i += 1
    buffer[o.i] = y
    if o.i == p
        sort!(buffer)
        o.nreps += 1
        o.i = 0
        smooth!(o.value, buffer, 1 / o.nreps)
    end
    o
end
fields_to_show(o::OrderStats) = [:value]

#--------------------------------------------------------------------# Moments
"""
First four non-central moments

    s = Series(randn(100), Moments())
"""
mutable struct Moments <: OnlineStat{0, 1}
    m::VecF
    nobs::Int
    Moments() = new(zeros(4), 0)
end
function fit!(o::Moments, y::Real, γ::Float64)
    o.nobs += 1
    @inbounds o.m[1] = smooth(o.m[1], y, γ)
    @inbounds o.m[2] = smooth(o.m[2], y * y, γ)
    @inbounds o.m[3] = smooth(o.m[3], y * y * y, γ)
    @inbounds o.m[4] = smooth(o.m[4], y * y * y * y, γ)
end
fields_to_show(o::Moments) = [:m]
Base.mean(o::Moments) = o.m[1]
Base.var(o::Moments) = (o.m[2] - o.m[1] ^ 2) * unbias(o)
Base.std(o::Moments) = sqrt.(var(o))
function StatsBase.skewness(o::Moments)
    v = value(o)
    (v[3] - 3.0 * v[1] * var(o) - v[1] ^ 3) / var(o) ^ 1.5
end
function StatsBase.kurtosis(o::Moments)
    v = value(o)
    (v[4] - 4.0 * v[1] * v[3] + 6.0 * v[1] ^ 2 * v[2] - 3.0 * v[1] ^ 4) / var(o) ^ 2 - 3.0
end
function Base.merge!(o1::Moments, o2::Moments, γ::Float64)
    smooth!(o1.m, o2.m, γ)
    o1.nobs += o2.nobs
    o1
end

#--------------------------------------------------------------------# QuantileSGD
"""
Approximate quantiles via stochastic gradient descent

    s = Series(randn(10_000), QuantileSGD(); weight = LearningRate())
"""
struct QuantileSGD <: OnlineStat{0, 1}
    value::VecF
    τ::VecF
    QuantileSGD(τ::VecF = [0.25, 0.5, 0.75]) = new(zeros(τ), τ)
    QuantileSGD(args...) = QuantileSGD(collect(args))
end
function fit!(o::QuantileSGD, y::Float64, γ::Float64)
    for i in eachindex(o.τ)
        @inbounds v = Float64(y < o.value[i]) - o.τ[i]
        @inbounds o.value[i] = subgrad(o.value[i], γ, v)
    end
end
function fitbatch!{T <: Real}(o::QuantileSGD, y::AVec{T}, γ::Float64)
    n2 = length(y)
    γ = γ / n2
    for yi in y
        for i in eachindex(o.τ)
            @inbounds v = Float64(yi < o.value[i]) - o.τ[i]
            @inbounds o.value[i] = subgrad(o.value[i], γ, v)
        end
    end
end

#--------------------------------------------------------------------# QuantileSGD
"""
Approximate quantiles via an online MM algorithm

    s = Series(randn(10_000), QuantileMM(); weight = LearningRate())
"""
mutable struct QuantileMM <: OnlineStat{0, 1}
    value::VecF
    τ::VecF
    # "sufficient statistics"
    s::VecF
    t::VecF
    o::Float64
    QuantileMM(τ::VecF = [.25, .5, .75]) = new(zeros(τ), τ, zeros(τ), zeros(τ), 0.0)
    QuantileMM(args...) = QuantileMM(collect(args))
end
fields_to_show(o::QuantileMM) = [:value, :τ]
function fit!(o::QuantileMM, y::Real, γ::Float64)
    o.o = smooth(o.o, 1.0, γ)
    @inbounds for j in 1:length(o.τ)
        w::Float64 = 1.0 / (abs(y - o.value[j]) + ϵ)
        o.s[j] = smooth(o.s[j], w * y, γ)
        o.t[j] = smooth(o.t[j], w, γ)
        o.value[j] = (o.s[j] + o.o * (2.0 * o.τ[j] - 1.0)) / o.t[j]
    end
end
function fitbatch!{T <: Real}(o::QuantileMM, y::AVec{T}, γ::Float64)
    n2 = length(y)
    γ = γ / n2
    o.o = smooth(o.o, 1.0, γ)
    @inbounds for yi in y
        for j in 1:length(o.τ)
            w::Float64 = 1.0 / abs(yi - o.value[j])
            o.s[j] = smooth(o.s[j], w * yi, γ)
            o.t[j] = smooth(o.t[j], w, γ)
        end
    end
    @inbounds for j in 1:length(o.τ)
        o.value[j] = (o.s[j] + o.o * (2.0 * o.τ[j] - 1.0)) / o.t[j]
    end
    o
end

#--------------------------------------------------------------------# Diff
"""
Track the difference and the last value

    s = Series(randn(100), Diff())
"""
mutable struct Diff{T <: Real} <: OnlineStat{0, 0}
    diff::T
    lastval::T
end
Diff() = Diff(0.0, 0.0)
Diff{T<:Real}(::Type{T}) = Diff(zero(T), zero(T))
Base.last(o::Diff) = o.lastval
Base.diff(o::Diff) = o.diff
function fit!{T<:AbstractFloat}(o::Diff{T}, x::Real, γ::Float64)
    v = convert(T, x)
    o.diff = v - last(o)
    o.lastval = v
end
function fit!{T<:Integer}(o::Diff{T}, x::Real, γ::Float64)
    v = round(T, x)
    o.diff = v - last(o)
    o.lastval = v
end

#--------------------------------------------------------------------# Sum
"""
Track the overall sum

    s = Series(randn(100), Sum())
"""
mutable struct Sum{T <: Real} <: OnlineStat{0, 0}
    sum::T
end
Sum() = Sum(0.0)
Sum{T<:Real}(::Type{T}) = Sum(zero(T))
Base.sum(o::Sum) = o.sum
function fit!{T<:AbstractFloat}(o::Sum{T}, x::Real, γ::Float64)
    v = convert(T, x)
    o.sum += v
end
function fit!{T<:Integer}(o::Sum{T}, x::Real, γ::Float64)
    v = round(T, x)
    o.sum += v
end
