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
_merge!(o::FitBeta, o2::FitBeta) = _merge!(o.var, o2.var)

#---------------------------------------------------------------------------------# Cauchy
"""
    FitCauchy(b=500)

Approximate parameter estimation of a Cauchy distribution.  Estimates are based on
approximated quantiles.  See [`Quantile`](@ref) and [`ExpandingHist`](@ref) for details on how the 
distribution is estimated.

# Example 
    o = fit!(FitCauchy(), randn(1000))
"""
mutable struct FitCauchy{T} <: OnlineStat{Number}
    q::Quantile{T}
end
FitCauchy(b = 500) = FitCauchy(Quantile([.25, .5, .75], b=b))
nobs(o::FitCauchy) = nobs(o.q)
_fit!(o::FitCauchy, y) = _fit!(o.q, y)
function value(o::FitCauchy)
    if nobs(o) > 1
        a, b, c = value(o.q)
        return b, 0.5 * (c - a)
    else
        return 0.0, 1.0
    end
end
_merge!(o::FitCauchy, o2::FitCauchy) = _merge!(o.q, o2.q)

#---------------------------------------------------------------------------------# Gamma
"""
    FitGamma(; weight)

Online parameter estimate of a Gamma distribution (Method of Moments).

# Example 
    using Random
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
_merge!(o::FitGamma, o2::FitGamma) = _merge!(o.v, o2.v)

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
_merge!(o::FitLogNormal, o2::FitLogNormal) = _merge!(o.v, o2.v)

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
_merge!(o::FitNormal, o2::FitNormal) = _merge!(o.v, o2.v)
Statistics.mean(o::FitNormal) = mean(o.v)
Statistics.var(o::FitNormal) = var(o.v)

function pdf(o::FitNormal, x::Number) 
    σ = std(o)
    1 / (sqrt(2π) * σ) * exp(-(x - mean(o))^2 / 2σ^2)
end
function cdf(o::FitNormal, x::Number) 
    .5 * (1.0 + erf_approx((x - mean(o)) / (std(o) * √2)))
end
# https://en.wikipedia.org/wiki/Error_function#Approximation_with_elementary_functions
function erf_approx(x)
    s = sign(x)
    p = 0.3275911
    a1 = 0.254829592
    a2 = -0.284496736
    a3 = 1.421413741
    a4 = -1.453152027
    a5 = 1.061405429
    t = 1 / (1 + p * s * x)
    s * (1 - (a1*t + a2*t^2 + a3*t^3 + a4*t^4 + a5*t^5) * exp(-x^2))
end

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
_merge!(o::FitMultinomial, o2::FitMultinomial) = _merge!(o.grp, o2.grp)

#---------------------------------------------------------------------------------# MvNormal
"""
    FitMvNormal(d)

Online parameter estimate of a `d`-dimensional MvNormal distribution (MLE).

# Example 

    y = randn(100, 2)
    o = fit!(FitMvNormal(2), eachrow(y))
"""
struct FitMvNormal <: OnlineStat{VectorOb}
    cov::CovMatrix{Float64}
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
        return zeros(nvars(o)), Matrix(1.0I, nvars(o), nvars(o))
    end
end
_merge!(o::FitMvNormal, o2::FitMvNormal) = _merge!(o.cov, o2.cov)
