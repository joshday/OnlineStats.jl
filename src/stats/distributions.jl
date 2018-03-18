#---------------------------------------------------------------------------------# Beta
"""
    FitBeta(; weight)

Online parameter estimate of a Beta distribution (Method of Moments).
"""
struct FitBeta{V<:Variance} <: OnlineStat{0}
    var::V
end
FitBeta(;kw...) = FitBeta(Variance(;kw...))
nobs(o::FitBeta) = nobs(o.var)
_fit!(o::FitBeta, y::Real) = fit!(o.var, y)
function value(o::FitBeta)
    if o.var.n > 1
        m = mean(o.var)
        v = var(o.var)
        α = m * (m * (1 - m) / v - 1)
        β = (1 - m) * (m * (1 - m) / v - 1)
        return α, β
    else
        return 1.0, 1.0
    end
end
Base.merge!(o::FitBeta, o2::FitBeta) = merge!(o.var, o2.var)

#---------------------------------------------------------------------------------# Cauchy
"""
    FitCauchy(; alg, rate)

Approximate parameter estimation of a Cauchy distribution.  Estimates are based on
quantiles, so that `alg` will be passed to [`Quantile`](@ref).
"""
mutable struct FitCauchy{T} <: OnlineStat{0}
    q::Quantile{T}
end
FitCauchy(alg = SGD(), kw...) = FitCauchy(Quantile([.25, .5, .75]; alg=alg, kw...))
nobs(o::FitCauchy) = nobs(o.q)
_fit!(o::FitCauchy, y) = _fit!(o.q, y)
function value(o::FitCauchy)
    if nobs(o) > 1
        return o.q.value[2], 0.5 * (o.q.value[3] - o.q.value[1])
    else
        return 0.0, 1.0
    end
end
Base.merge!(o::FitCauchy, o2::FitCauchy) = merge!(o.q, o2.q)

#---------------------------------------------------------------------------------# Gamma
"""
    FitGamma(; weight)

Online parameter estimate of a Gamma distribution (Method of Moments).
"""
struct FitGamma <: OnlineStat{0}
    v::Variance
end
FitGamma() = FitGamma(Variance())
nobs(o::FitGamma) = nobs(o.v)
_fit!(o::FitGamma, y) = _fit!(o.v, y)
function value(o::FitGamma)
    if nobs(o) > 1
        m = mean(o.v)
        θ = var(o.v) / m
        α = m / θ
        return α, θ
    else
        return 1.0, 1.0
    end
end
Base.merge!(o::FitGamma, o2::FitGamma) = merge!(o.v, o2.v)

#---------------------------------------------------------------------------------# LogNormal
"""
    FitLogNormal()

Online parameter estimate of a LogNormal distribution (MLE).
"""
struct FitLogNormal <: OnlineStat{0}
    v::Variance
    FitLogNormal() = new(Variance())
end
nobs(o::FitLogNormal) = nobs(o.v)
_fit!(o::FitLogNormal, y) = _fit!(o.v, log(y))
function value(o::FitLogNormal)
    if nobs(o) > 1
        return mean(o.v), std(o.v)
    else
        return 0.0, 1.0
    end
end
Base.merge!(o::FitLogNormal, o2::FitLogNormal) = merge!(o.v, o2.v)

#---------------------------------------------------------------------------------# Normal
"""
    FitNormal()

Calculate the parameters of a normal distribution via maximum likelihood.
"""
struct FitNormal{V <: Variance} <: OnlineStat{0}
    v::V
end
FitNormal(;kw...) = FitNormal(Variance(;kw...))
_fit!(o::FitNormal, y::Real) = _fit!(o.v, y)
nobs(o::FitNormal) = nobs(o.v)
function value(o::FitNormal)
    if nobs(o) > 1
        return mean(o.v), std(o.v)
    else
        return 0.0, 1.0
    end
end
Base.merge!(o::FitNormal, o2::FitNormal) = (merge!(o.v, o2.v); o)
Base.mean(o::FitNormal) = mean(o.v)
Base.var(o::FitNormal) = var(o.v)

function pdf(o::FitNormal, x::Number) 
    σ = std(o)
    return 1 / (sqrt(2π) * σ) * exp(-(x - mean(o))^2 / 2σ^2)
end
cdf(o::FitNormal, x::Number) = .5 * (1.0 + erf((x - mean(o)) / (std(o) * √2)))

#-----------------------------------------------------------------------# Multinomial
"""
    FitMultinomial(p)

Online parameter estimate of a Multinomial distribution.  The sum of counts does not need
to be consistent across observations.  Therefore, the `n` parameter of the Multinomial
distribution is returned as 1.
"""
struct FitMultinomial{T} <: OnlineStat{1}
    mvmean::Group{T}
end
FitMultinomial(p::Integer) = FitMultinomial(p * Mean())
_fit!(o::FitMultinomial, y) = _fit!(o.mvmean, y)
function value(o::FitMultinomial)
    m = value(o.mvmean)
    p = length(o.mvmean)
    outvec = all(x-> x==0.0, m) ? ones(p) ./ p : collect(m) ./ sum(m)
    return 1, outvec
end
Base.merge!(o::FitMultinomial, o2::FitMultinomial) = merge!(o.mvmean, o2.mvmean)

#---------------------------------------------------------------------------------# MvNormal
"""
    FitMvNormal(d)

Online parameter estimate of a `d`-dimensional MvNormal distribution (MLE).
"""
struct FitMvNormal <: OnlineStat{1}
    cov::CovMatrix
    FitMvNormal(p::Integer) = new(CovMatrix(p))
end
Base.length(o::FitMvNormal) = length(o.cov)
nobs(o::FitMvNormal) = nobs(o.cov)
_fit!(o::FitMvNormal, y) = _fit!(o.cov, y)
function value(o::FitMvNormal)
    c = cov(o.cov)
    if isposdef(c)
        return mean(o.cov), c
    else
        return zeros(length(o)), eye(length(o))
    end
end
Base.merge!(o::FitMvNormal, o2::FitMvNormal) = merge!(o.cov, o2.cov)