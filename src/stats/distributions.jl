#---------------------------------------------------------------------------------# Beta
"""
    FitBeta()

Online parameter estimate of a Beta distribution (Method of Moments).

    using Distributions, OnlineStats
    y = rand(Beta(3, 5), 1000)
    o = FitBeta()
    s = Series(y, o)
    Beta(value(o)...)
"""
struct FitBeta <: ExactStat{0}
    var::Variance
    FitBeta() = new(Variance())
end
fit!(o::FitBeta, y::Real, γ::Float64) = fit!(o.var, y, γ)
function value(o::FitBeta)
    if o.var.nobs > 1
        m = mean(o.var)
        v = var(o.var)
        α = m * (m * (1 - m) / v - 1)
        β = (1 - m) * (m * (1 - m) / v - 1)
        return α, β
    else
        return 1.0, 1.0
    end
end
Base.merge!(o::FitBeta, o2::FitBeta, γ::Float64) = merge!(o.var, o2.var, γ)

#---------------------------------------------------------------------------------# Categorical
"""
    FitCategorical(T)

Fit a categorical distribution where the inputs are of type `T`.

    using Distributions
    s = Series(rand(1:10, 1000), FitCategorical(Int))
    value(s)

    vals = ["small", "medium", "large"]
    o = FitCategorical(String)
    s = Series(rand(vals, 1000), o)
    value(o)
"""
mutable struct FitCategorical{T} <: ExactStat{0}
    d::Dict{T, Int}
    nobs::Int
    FitCategorical{T}() where {T} = new(Dict{T, Int}(), 0)
end
FitCategorical(t::Type) = FitCategorical{t}()
function fit!{T}(o::FitCategorical{T}, y::T, γ::Float64)
    o.nobs += 1
    haskey(o.d, y) ? (o.d[y] += 1) : (o.d[y] = 1)
end
value(o::FitCategorical) = ifelse(o.nobs > 0, collect(values(o.d)) ./ o.nobs, zeros(0))
Base.keys(o::FitCategorical) = keys(o.d)
Base.values(o::FitCategorical) = values(o.d)
function Base.merge!(o::T, o2::T, γ::Float64) where {T <: FitCategorical}
    merge!(o.d, o2.d)
    o.nobs += o2.nobs
end

#---------------------------------------------------------------------------------# Cauchy
"""
    FitCauchy()

Online parameter estimate of a Cauchy distribution.

    using Distributions
    y = rand(Cauchy(0, 10), 10_000)
    o = FitCauchy()
    s = Series(y, o)
    Cauchy(value(o)...)
"""
mutable struct FitCauchy <: StochasticStat{0}
    q::QuantileMM
    nobs::Int
    FitCauchy() = new(QuantileMM(), 0)
end
fit!(o::FitCauchy, y::Real, γ::Float64) = (o.nobs += 1; fit!(o.q, y, γ))
function value(o::FitCauchy)
    if o.nobs > 1
        return o.q.value[2], 0.5 * (o.q.value[3] - o.q.value[1])
    else
        return 0.0, 1.0
    end
end
function Base.merge!(o::FitCauchy, o2::FitCauchy, γ::Float64) 
    o.nobs += o2.nobs
    merge!(o.q, o2.q, γ) 
end

#---------------------------------------------------------------------------------# Gamma
"""
    FitGamma()

Online parameter estimate of a Gamma distribution (Method of Moments).

    using Distributions
    y = rand(Gamma(5, 1), 1000)
    o = FitGamma()
    s = Series(y, o)
    Gamma(value(o)...)
"""
# method of moments. TODO: look at Distributions for MLE
struct FitGamma <: ExactStat{0}
    var::Variance
end
FitGamma() = FitGamma(Variance())
fit!(o::FitGamma, y::Real, γ::Float64) = fit!(o.var, y, γ)
function value(o::FitGamma)
    if o.var.nobs > 1
        m = mean(o.var)
        v = var(o.var)
        θ = v / m
        α = m / θ
        return α, θ
    else
        return 1.0, 1.0
    end
end
Base.merge!(o::FitGamma, o2::FitGamma, γ::Float64) = merge!(o.var, o2.var, γ)

#---------------------------------------------------------------------------------# LogNormal
"""
    FitLogNormal()

Online parameter estimate of a LogNormal distribution (MLE).

    using Distributions
    y = rand(LogNormal(3, 4), 1000)
    o = FitLogNormal()
    s = Series(y, o)
    LogNormal(value(o)...)
"""
struct FitLogNormal <: ExactStat{0}
    var::Variance
    FitLogNormal() = new(Variance())
end
fit!(o::FitLogNormal, y::Real, γ::Float64) = fit!(o.var, log(y), γ)
function value(o::FitLogNormal)
    if o.var.nobs > 1
        return mean(o.var), std(o.var)
    else
        return 0.0, 1.0
    end
end
Base.merge!(o::FitLogNormal, o2::FitLogNormal, γ::Float64) = merge!(o.var, o2.var, γ)

#---------------------------------------------------------------------------------# Normal
"""
    FitNormal()

Online parameter estimate of a Normal distribution (MLE).

    using Distributions
    y = rand(Normal(-3, 4), 1000)
    o = FitNormal()
    s = Series(y, o)
    Normal(value(o)...)
"""
struct FitNormal <: ExactStat{0}
    var::Variance
    FitNormal() = new(Variance())
end
fit!(o::FitNormal, y::Real, γ::Float64) = fit!(o.var, y, γ)
function value(o::FitNormal)
    if o.var.nobs > 1
        return mean(o.var), std(o.var)
    else
        return 0.0, 1.0
    end
end
Base.merge!(o::FitNormal, o2::FitNormal, γ::Float64) = merge!(o.var, o2.var, γ)

#---------------------------------------------------------------------------------# Multinomial
# TODO: Allow each observation to have a different n
"""
    FitMultinomial(p)

Online parameter estimate of a Multinomial distribution.  The sum of counts does not need
to be consistent across observations.  Therefore, the `n` parameter of the Multinomial
distribution is returned as 1.

    using Distributions
    y = rand(Multinomial(10, [.2, .2, .6]), 1000)
    o = FitMultinomial(3)
    s = Series(y', o)
    Multinomial(value(o)...)
"""
mutable struct FitMultinomial <: ExactStat{1}
    mvmean::MV{Mean}
    nobs::Int
    FitMultinomial(p::Integer) = new(MV(p, Mean()), 0)
end
function fit!{T<:Real}(o::FitMultinomial, y::AbstractVector{T}, γ::Float64)
    o.nobs += 1
    fit!(o.mvmean, y, γ)
    o
end
function value(o::FitMultinomial)
    m = value(o.mvmean)
    p = length(o.mvmean.stats)
    if o.nobs > 0
        return 1, m / sum(m)
    else
        return 1, ones(p) / p
    end
end
function Base.merge!(o::FitMultinomial, o2::FitMultinomial, γ::Float64)
    o.nobs += o2.nobs
    merge!(o.mvmean, o2.mvmean, γ)
end

#---------------------------------------------------------------------------------# MvNormal
"""
    FitMvNormal(d)

Online parameter estimate of a `d`-dimensional MvNormal distribution (MLE).

    using Distributions
    y = rand(MvNormal(zeros(3), eye(3)), 1000)
    o = FitMvNormal(3)
    s = Series(y', o)
    MvNormal(value(o)...)
"""
struct FitMvNormal <: ExactStat{1}
    cov::CovMatrix
    FitMvNormal(p::Integer) = new(CovMatrix(p))
end
Base.length(o::FitMvNormal) = length(o.cov)
fit!{T<:Real}(o::FitMvNormal, y::AbstractVector{T}, γ::Float64) = fit!(o.cov, y, γ)
function value(o::FitMvNormal)
    c = cov(o.cov)
    if isposdef(c)
        return mean(o.cov), c
    else
        return zeros(length(o)), eye(length(o))
    end
end
Base.merge!(o::FitMvNormal, o2::FitMvNormal, γ::Float64) = merge!(o.cov, o2.cov, γ)
