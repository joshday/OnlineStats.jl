#---------------------------------------------------------------------------------# Beta
"""
    FitBeta(; weight)

Online parameter estimate of a Beta distribution (Method of Moments).

# Example 
    o = fit!(FitBeta(), rand(1000))
"""
struct FitBeta{V<:Variance} <: OnlineStat{Number}
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

# Example 
    o = fit!(FitCauchy(), randn(1000))
"""
mutable struct FitCauchy{T} <: OnlineStat{Number}
    q::Quantile{T}
end
FitCauchy(alg = OMAS(), kw...) = FitCauchy(Quantile([.25, .5, .75]; alg=alg, kw...))
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

# Example 
    o = fit!(FitGamma(), randexp(10^5))
"""
struct FitGamma <: OnlineStat{Number}
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

# Example 
    o = fit!(FitLogNormal(), exp.(randn(10^5)))
"""
struct FitLogNormal <: OnlineStat{Number}
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

# Example 
    o = fit!(FitNormal(), randn(1000))
"""
struct FitNormal{V <: Variance} <: OnlineStat{Number}
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
cdf(o::FitNormal, x::Number) = .5 * (1.0 + SpecialFunctions.erf((x - mean(o)) / (std(o) * √2)))

#-----------------------------------------------------------------------# Multinomial
"""
    FitMultinomial(p)

Online parameter estimate of a Multinomial distribution.  The sum of counts does not need
to be consistent across observations.  Therefore, the `n` parameter of the Multinomial
distribution is returned as 1.

# Example 
    x = [1 2 3; 4 8 12]
    fit!(FitMultinomial(3), x)
"""
mutable struct FitMultinomial{T} <: OnlineStat{VectorOb}
    grp::Group{T}
end

FitMultinomial(p::Int=0) = FitMultinomial(p * Mean())
_fit!(o::FitMultinomial, y) = _fit!(o.grp, y)
nobs(o::FitMultinomial) = nobs(o.grp)
function value(o::FitMultinomial)
    m = value.(o.grp.stats)
    p = length(o.grp)
    outvec = all(x-> x==0.0, m) ? ones(p) ./ p : collect(m) ./ sum(m)
    return 1, outvec
end
Base.merge!(o::FitMultinomial, o2::FitMultinomial) = merge!(o.grp, o2.grp)

#---------------------------------------------------------------------------------# MvNormal
"""
    FitMvNormal(d)

Online parameter estimate of a `d`-dimensional MvNormal distribution (MLE).

# Example 

    y = randn(100, 2)
    o = fit!(FitMvNormal(2), y)
"""
struct FitMvNormal <: OnlineStat{VectorOb}
    cov::CovMatrix
    FitMvNormal(p::Integer) = new(CovMatrix(p))
end
nvars(o::FitMvNormal) = nvars(o.cov)
nobs(o::FitMvNormal) = nobs(o.cov)
_fit!(o::FitMvNormal, y) = _fit!(o.cov, y)
function value(o::FitMvNormal)
    c = cov(o.cov)
    if isposdef(c)
        return mean(o.cov), c
    else
        return zeros(nvars(o)), eye(nvars(o))
    end
end
Base.merge!(o::FitMvNormal, o2::FitMvNormal) = merge!(o.cov, o2.cov)