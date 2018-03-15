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

#---------------------------------------------------------------------------------# Cauchy
"""
    FitCauchy(alg = SGD())

Approximate parameter estimation of a Cauchy distribution.  Estimates are based on
quantiles, so that `alg` will be passed to [`Quantile`](@ref).

    using Distributions
    y = rand(Cauchy(0, 10), 10_000)
    o = FitCauchy(SGD())
    s = Series(y, o)
    Cauchy(value(o)...)
"""
mutable struct FitCauchy{T} <: StochasticStat{0}
    q::Quantile{T}
    nobs::Int
end
FitCauchy(alg = OMAS()) = FitCauchy(Quantile([.25, .5, .75], alg), 0)
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
Base.mean(o::FitNormal) = mean(o.var)
Base.std(o::FitNormal) = std(o.var)
nobs(o::FitNormal) = nobs(o.var)
cdf(o::FitNormal, x::Number) = .5 * (1.0 + erf((x - mean(o)) / (std(o) * √2)))

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
struct FitMultinomial{T} <: ExactStat{1}
    mvmean::Group{T}
end
FitMultinomial(p::Integer) = FitMultinomial(Group(ntuple(x -> Mean(), p)))
fit!{T<:Real}(o::FitMultinomial, y::AbstractVector{T}, γ::Float64) = fit!(o.mvmean, y, γ)
function value(o::FitMultinomial)
    m = value(o.mvmean)
    p = length(o.mvmean)
    outvec = all(x-> x==0.0, m) ? ones(p) ./ p : collect(m) ./ sum(m)
    return 1, outvec
end
Base.merge!(o::FitMultinomial, o2::FitMultinomial, γ::Float64) = merge!(o.mvmean, o2.mvmean, γ)

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
