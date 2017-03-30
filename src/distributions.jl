#--------------------------------------------------------------# common
const DistributionStat{I} = OnlineStat{I, Ds.Distribution}
for f in [:mean, :var, :std, :params, :ncategories, :cov, :probs, :rand]
    @eval Ds.$f(d::DistributionStat) = Ds.$f(value(d))
end
for f in [:pdf, :cdf, :logpdf, :rand!]
    @eval Ds.$f(d::DistributionStat, arg) = Ds.$f(value(d), arg)
end



#--------------------------------------------------------------# Beta
"""
Online parameter estimate of a Beta distribution (Method of Moments)

    using Distributions
    y = rand(Beta(3, 5), 1000)
    s = Series(y, FitBeta())
"""
struct FitBeta <: DistributionStat{0}
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
        return Ds.Beta(α, β)
    else
        return Ds.Beta()
    end
end


#------------------------------------------------------------------# Categorical
mutable struct FitCategorical{T<:Any} <: DistributionStat{0}
    d::Dict{T, Int}
    nobs::Int
    FitCategorical{T}() where T<:Any = new(Dict{T, Int}(), 0)
end
FitCategorical(t::Type) = FitCategorical{t}()
function fit!{T}(o::FitCategorical{T}, y::T, γ::Float64)
    o.nobs += 1
    haskey(o.d, y) ? (o.d[y] += 1) : (o.d[y] = 1)
end
function value(o::FitCategorical)
    o.nobs > 0 ? Ds.Categorical(collect(values(o.d)) ./ o.nobs) : Ds.Categorical(1)
end
Base.keys(o::FitCategorical) = keys(o.d)
# function _fit!(o::FitCategorical, y::Union{Real, AbstractString, Symbol}, γ::Float64)
#     if haskey(o.d, y)
#         o.d[y] += 1
#     else
#         o.d[y] = 1
#     end
#     o
# end
# # FitCategorical allows more than just Real input, so it needs special fit! methods
# function fit!(o::FitCategorical, y::Union{AbstractString, Symbol})
#     updatecounter!(o)
#     γ = weight(o)
#     _fit!(o, y, γ)
#     o
# end
# function fit!{T <: Union{AbstractString, Symbol}}(o::FitCategorical, y::AVec{T})
#     for yi in y
#         fit!(o, yi)
#     end
#     o
# end
#
# sortpairs(o::FitCategorical) = sort(collect(o.d), by = x -> 1 / x[2])
# # function Base.sort!(o::FitCategorical)
# #     if nobs(o) > 0
# #         sortedpairs = sortpairs(o)
# #         counts = zeros(length(sortedpairs))
# #         for i in 1:length(sortedpairs)
# #             counts[i] = sortedpairs[i][2]
# #         end
# #         o.value = Ds.Categorical(counts / sum(counts))
# #     end
# # end
# function value(o::FitCategorical)
#     if nobs(o) > 0
#         o.value = Ds.Categorical(collect(values(o.d)) ./ nobs(o))
#     end
# end
# function Base.show(io::IO, o::FitCategorical)
#     header(io, "FitCategorical")
#     print_item(io, "value", value(o))
#     print_item(io, "labels", keys(o.d))
#     print_item(io, "nobs", nobs(o))
# end
# updatecounter!(o::FitCategorical, n2::Int = 1) = (o.nobs += n2)
# weight(o::FitCategorical, n2::Int = 1) = 0.0
# nobs(o::FitCategorical) = o.nobs
#
#
#------------------------------------------------------------------# Cauchy
"""
Online parameter estimate of a Cauchy distribution

    using Distributions
    y = rand(Cauchy(0, 10), 10_000)
    s = Series(y, FitCauchy(); weight = LearningRate())
"""
mutable struct FitCauchy <: DistributionStat{0}
    q::QuantileMM
    nobs::Int
    FitCauchy() = new(QuantileMM(), 0)
end
fit!(o::FitCauchy, y::Real, γ::Float64) = (o.nobs += 1; fit!(o.q, y, γ))
function value(o::FitCauchy)
    if o.nobs > 1
        return Ds.Cauchy(o.q.value[2], 0.5 * (o.q.value[3] - o.q.value[1]))
    else
        return Ds.Cauchy()
    end
end


#------------------------------------------------------------------------# Gamma
"""
Online parameter estimate of a Gamma distribution (Method of Moments)

    using Distributions
    y = rand(Gamma(5, 1), 1000)
    s = Series(y, FitGamma())
"""
# method of moments. TODO: look at Distributions for MLE
struct FitGamma <: DistributionStat{0}
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
        return Ds.Gamma(α, θ)
    else
        return Ds.Gamma()
    end
end


#-----------------------------------------------------------------------# LogNormal
"""
Online parameter estimate of a LogNormal distribution (MLE)

    using Distributions
    y = rand(LogNormal(3, 4), 1000)
    s = Series(y, FitLogNormal())
"""
struct FitLogNormal <: DistributionStat{0}
    var::Variance
    FitLogNormal() = new(Variance())
end
fit!(o::FitLogNormal, y::Real, γ::Float64) = fit!(o.var, log(y), γ)
function value(o::FitLogNormal)
    o.var.nobs > 1 ? Ds.LogNormal(mean(o.var), std(o.var)) : Ds.LogNormal()
end


#-----------------------------------------------------------------------# Normal
"""
Online parameter estimate of a Normal distribution (MLE)

    using Distributions
    y = rand(Normal(-3, 4), 1000)
    s = Series(y, FitNormal())
"""
struct FitNormal <: DistributionStat{0}
    var::Variance
    FitNormal() = new(Variance())
end
fit!(o::FitNormal, y::Real, γ::Float64) = fit!(o.var, y, γ)
function value(o::FitNormal)
    o.var.nobs > 1 ? Ds.Normal(mean(o.var), std(o.var)) : Ds.Normal()
end


#-----------------------------------------------------------------------# Multinomial
mutable struct FitMultinomial <: DistributionStat{1}
    mvmean::MV{Mean}
    nobs::Int
    FitMultinomial(p::Integer) = new(MV(p, Mean()), 0)
end
function fit!{T<:Real}(o::FitMultinomial, y::AVec{T}, γ::Float64)
    o.nobs += 1
    fit!(o.mvmean, y, γ)
    o
end
function value(o::FitMultinomial)
    m = value(o.mvmean)
    p = length(o.mvmean.stats)
    o.nobs > 0 ? Ds.Multinomial(1, m / sum(m)) : Ds.Multinomial(1, ones(p) / p)
end


#---------------------------------------------------------------------# MvNormal
"""
Online parameter estimate of a MvNormal distribution (MLE)

    using Distributions
    y = rand(MvNormal(zeros(3), eye(3)), 1000)
    s = Series(y', FitMvNormal(3))
"""
struct FitMvNormal<: DistributionStat{1}
    cov::CovMatrix
    FitMvNormal(p::Integer) = new(CovMatrix(p))
end
Base.length(o::FitMvNormal) = length(o.cov)
fit!{T<:Real}(o::FitMvNormal, y::AVec{T}, γ::Float64) = fit!(o.cov, y, γ)
function value(o::FitMvNormal)
    c = cov(o.cov)
    if isposdef(c)
        return Ds.MvNormal(mean(o.cov), c)
    else
        warn("Covariance not positive definite.  More data needed.")
        return Ds.MvNormal(zeros(length(o)), eye(length(o)))
    end
end
