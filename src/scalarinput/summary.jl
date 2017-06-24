#--------------------------------------------------------------------# Mean
"""
```julia
Mean()
```
Univariate mean.
### Example
```julia
s = Series(randn(100), Mean())
value(s)
```
"""
mutable struct Mean <: OnlineStat{0, 0}
    μ::Float64
    Mean() = new(0.0)
end
fit!(o::Mean, y::Real, γ::Float64) = (o.μ = smooth(o.μ, y, γ))
fitbatch!(o::Mean, y::AVec, γ::Float64) = (o.μ = smooth(o.μ, mean(y), γ))
Base.merge!(o::Mean, o2::Mean, γ::Float64) = fit!(o, value(o2), γ)
Base.mean(o::Mean) = value(o)

#--------------------------------------------------------------------# Variance
"""
```julia
Variance()
```
Univariate variance.
### Example
```julia
s = Series(randn(100), Variance())
value(s)
```
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
```julia
Extrema()
```

Maximum and minimum.
### Example
```julia
s = Series(randn(100), Extrema())
value(s)
```
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
function Base.merge!(o::Extrema, o2::Extrema, γ::Float64)
    o.min = min(o.min, o2.min)
    o.max = max(o.max, o2.max)
    o
end
value(o::Extrema) = (o.min, o.max)
Base.extrema(o::Extrema) = value(o)

#--------------------------------------------------------------------# OrderStats
"""
```julia
OrderStats(b)
```
Average order statistics with batches of size `b`.
### Example
```julia
s = Series(randn(1000), OrderStats(10))
value(s)
```
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
```julia
Moments()
```
First four non-central moments.
### Example
```julia
s = Series(randn(1000), Moments(10))
value(s)
```
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
function skewness(o::Moments)
    v = value(o)
    (v[3] - 3.0 * v[1] * var(o) - v[1] ^ 3) / var(o) ^ 1.5
end
function kurtosis(o::Moments)
    v = value(o)
    (v[4] - 4.0 * v[1] * v[3] + 6.0 * v[1] ^ 2 * v[2] - 3.0 * v[1] ^ 4) / var(o) ^ 2 - 3.0
end
function Base.merge!(o1::Moments, o2::Moments, γ::Float64)
    smooth!(o1.m, o2.m, γ)
    o1.nobs += o2.nobs
    o1
end

#--------------------------------------------------------------------# StochasticLoss
"""
```julia
    s = Series(randn(1000), StochasticLoss(QuantileLoss(.7)))
```
Minimize a loss (from LossFunctions.jl) using stochastic gradient descent.
### Example
```julia
o1 = StochasticLoss(QuantileLoss(.7))  # approx. .7 quantile
o2 = StochasticLoss(L2DistLoss())      # approx. mean
o3 = StochasticLoss(L1DistLoss())      # approx. median
s = Series(randn(10_000), o1, o2, o3)
```
"""
mutable struct StochasticLoss{L<:Loss} <: StochasticStat{0, 0}
    value::Float64
    loss::L
end
StochasticLoss(loss::Loss) = StochasticLoss(0.0, loss)
fit!(o::StochasticLoss, y::Float64, γ::Float64) = (o.value -= γ * deriv(o.loss, y, o.value))

#--------------------------------------------------------------------# QuantileISGD
"""
```julia
QuantileISGD()
```
Approximate quantiles via implicit stochastic gradient descent.
### Example
```julia
s = Series(randn(1000), LearningRate(.7), QuantileISGD())
value(s)
```
"""
struct QuantileISGD <: StochasticStat{0, 1}
    value::VecF
    τ::VecF
    x::VecF
    K::Int
    QuantileISGD(τ::VecF = [0.25, 0.5, 0.75], K::Int = 10) = new(zeros(τ), τ, zeros(τ), K)
    QuantileISGD(args...) = QuantileSGD(collect(args))
end
function fit!(o::QuantileISGD, y::Float64, γ::Float64)
    for i in eachindex(o.τ)
        for k in 1:o.K
            v = o.value[i] - γ * deriv(QuantileLoss(o.τ[i]), y, o.value[i])
            o.x[i] = smooth(o.x[i], v, 10 / k)  # TODO: find best constant for c / k
        end
        o.value[i] = o.x[i]
    end
end


#--------------------------------------------------------------------# QuantileSGD
"""
```julia
QuantileSGD()
```
Approximate quantiles via stochastic gradient descent.
### Example
```julia
s = Series(randn(1000), LearningRate(.7), QuantileSGD())
value(s)
```
"""
struct QuantileSGD <: StochasticStat{0, 1}
    value::VecF
    τ::VecF
    QuantileSGD(τ::VecF = [0.25, 0.5, 0.75]) = new(zeros(τ), τ)
    QuantileSGD(args...) = QuantileSGD(collect(args))
end
function fit!(o::QuantileSGD, y::Float64, γ::Float64)
    for i in eachindex(o.τ)
        @inbounds o.value[i] -= γ * deriv(QuantileLoss(o.τ[i]), y, o.value[i])
    end
end
function fitbatch!{T <: Real}(o::QuantileSGD, y::AVec{T}, γ::Float64)
    g = zeros(y)
    for i in eachindex(o.τ)
        g .= deriv.(QuantileLoss(o.τ[i]), y, o.value[i])
        @inbounds o.value[i] -= γ * mean(g)
    end
end
function Base.merge!(o::QuantileSGD, o2::QuantileSGD, γ::Float64)
    o.τ == o2.τ || throw(ArgumentError("objects track different quantiles"))
    smooth!(o.value, o2.value, γ)
end

#--------------------------------------------------------------------# QuantileMM
"""
```julia
QuantileMM()
```
Approximate quantiles via an online MM algorithm.
### Example
```julia
s = Series(randn(1000), LearningRate(.7), QuantileMM())
value(s)
```
"""
mutable struct QuantileMM <: StochasticStat{0, 1}
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
```julia
Diff()
```
Track the difference and the last value.
### Example
```julia
s = Series(randn(1000), Diff())
value(s)
```
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
```julia
Sum()
```
Track the overall sum.
### Example
```julia
s = Series(randn(1000), Sum())
value(s)
```
"""
mutable struct Sum{T <: Real} <: OnlineStat{0, 0}
    sum::T
end
Sum() = Sum(0.0)
Sum{T<:Real}(::Type{T}) = Sum(zero(T))
Base.sum(o::Sum) = o.sum
fit!{T<:AbstractFloat}(o::Sum{T}, x::Real, γ::Float64) = (v = convert(T, x); o.sum += v)
fit!{T<:Integer}(o::Sum{T}, x::Real, γ::Float64) =       (v = round(T, x);   o.sum += v)
fitbatch!(o::Sum, y::AVec, γ::Float64) = fit!(o, sum(y), γ)
