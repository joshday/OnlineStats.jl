# For DistributionStat objects
# fit! methods should only update "sufficient statistics"
# value methods should create the distribution

#--------------------------------------------------------------# common
abstract type DistributionStat{I<:Input} <: OnlineStat{I} end
for f in [:mean, :var, :std, :params, :ncategories, :cov]
    @eval Ds.$f(d::DistributionStat) = $f(value(d))
end
Base.rand(d::DistributionStat, args...) = rand(value(d), args...)


#--------------------------------------------------------------# Beta
mutable struct FitBeta <: DistributionStat{ScalarInput}
    value::Ds.Beta
    var::Variance
end
FitBeta() = FitBeta(Ds.Beta(), Variance())
fit!(o::FitBeta, y::Real, γ::Float64) = _fit!(o.var, y, γ)
function value(o::FitBeta)
    if nobs(o) > 1
        m = mean(o.var)
        v = var(o.var)
        α = m * (m * (1 - m) / v - 1)
        β = (1 - m) * (m * (1 - m) / v - 1)
        o.value = Ds.Beta(α, β)
    end
end


# #------------------------------------------------------------------# Categorical
# # Ignores weight
# """
# Find the proportions for each unique input.  Categories are sorted by proportions.
# Ignores `Weight`.
#
# ```julia
# o = FitCategorical(y)
# ```
# """
# type FitCategorical{T<:Any} <: DistributionStat{ScalarInput}
#     value::Ds.Categorical
#     d::Dict{T, Int}
#     nobs::Int
# end
# FitCategorical(T::DataType = Any) = FitCategorical(Ds.Categorical(1), Dict{T, Int}(), 0)
# function FitCategorical(y)
#     o = FitCategorical(eltype(y))
#     fit!(o, y)
#     o
# end
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
# #------------------------------------------------------------------# Cauchy
# type FitCauchy{W<:Weight} <: DistributionStat{ScalarInput}
#     value::Ds.Cauchy
#     q::QuantileMM{W}
# end
# FitCauchy(wgt::Weight = LearningRate()) = FitCauchy(Ds.Cauchy(), QuantileMM(wgt))
# _fit!(o::FitCauchy, y::Real, γ::Float64) = _fit!(o.q, y, γ)
# nobs(o::FitCauchy) = nobs(o.q)
# function value(o::FitCauchy)
#     o.value = Ds.Cauchy(o.q.value[2], 0.5 * (o.q.value[3] - o.q.value[1]))
# end
# updatecounter!(o::FitCauchy, n2::Int = 1) = updatecounter!(o.q, n2)
# weight(o::FitCauchy, n2::Int = 1) = weight(o.q, n2)
#
#
# #------------------------------------------------------------------------# Gamma
# # method of moments, TODO: look at Distributions for MLE
# type FitGamma{W<:Weight} <: DistributionStat{ScalarInput}
#     value::Ds.Gamma
#     var::Variance{W}
# end
# FitGamma(wgt::Weight = EqualWeight()) = FitGamma(Ds.Gamma(), Variance(wgt))
# _fit!(o::FitGamma, y::Real, γ::Float64) = _fit!(o.var, y, γ)
# nobs(o::FitGamma) = nobs(o.var)
# function value(o::FitGamma)
#     m = mean(o.var)
#     v = var(o.var)
#     θ = v / m
#     α = m / θ
#     if nobs(o) > 1
#         o.value = Ds.Gamma(α, θ)
#     end
# end
# updatecounter!(o::FitGamma, n2::Int = 1) = updatecounter!(o.var, n2)
# weight(o::FitGamma, n2::Int = 1) = weight(o.var, n2)
#
#
# #-----------------------------------------------------------------------# LogNormal
# type FitLogNormal{W<:Weight} <: DistributionStat{ScalarInput}
#     value::Ds.LogNormal
#     var::Variance{W}
# end
# FitLogNormal(wgt::Weight = EqualWeight()) = FitLogNormal(Ds.LogNormal(), Variance(wgt))
# nobs(o::FitLogNormal) = nobs(o.var)
# _fit!(o::FitLogNormal, y::Real, γ::Float64) = _fit!(o.var, log(y), γ)
# function value(o::FitLogNormal)
#     if nobs(o) > 1
#         o.value = Ds.LogNormal(mean(o.var), std(o.var))
#     end
# end
# updatecounter!(o::FitLogNormal, n2::Int = 1) = updatecounter!(o.var, n2)
# weight(o::FitLogNormal, n2::Int = 1) = weight(o.var, n2)
#
#
# #-----------------------------------------------------------------------# Normal
# type FitNormal{W<:Weight} <: DistributionStat{ScalarInput}
#     value::Ds.Normal
#     var::Variance{W}
# end
# FitNormal(wgt::Weight = EqualWeight()) = FitNormal(Ds.Normal(), Variance(wgt))
# nobs(o::FitNormal) = nobs(o.var)
# _fit!(o::FitNormal, y::Real, γ::Float64) = _fit!(o.var, y, γ)
# function value(o::FitNormal)
#     if nobs(o) > 1
#         o.value = Ds.Normal(mean(o.var), std(o.var))
#     end
# end
# updatecounter!(o::FitNormal, n2::Int = 1) = updatecounter!(o.var, n2)
# weight(o::FitNormal, n2::Int = 1) = weight(o.var, n2)
#
#
# #-----------------------------------------------------------------------# Multinomial
# type FitMultinomial{W<:Weight} <: DistributionStat{VectorInput}
#     value::Ds.Multinomial
#     means::Means{W}
# end
# function FitMultinomial(p::Integer, wgt::Weight = EqualWeight())
#     FitMultinomial(Ds.Multinomial(1, ones(p) / p), Means(p, wgt))
# end
# nobs(o::FitMultinomial) = nobs(o.means)
# _fit!{T<:Real}(o::FitMultinomial, y::AVec{T}, γ::Float64) = _fit!(o.means, y, γ)
# function value(o::FitMultinomial)
#     m = mean(o.means)
#     if nobs(o) > 0
#         o.value = Ds.Multinomial(round(Int, sum(m)), m / sum(m))
#     end
#     o.value
# end
# updatecounter!(o::FitMultinomial, n2::Int = 1) = updatecounter!(o.means, n2)
# weight(o::FitMultinomial, n2::Int = 1) = weight(o.means, n2)
#
#
# #--------------------------------------------------------------# DirichletMultinomial
# # TODO
# # """
# # Dirichlet-Multinomial estimation using Type 1 Online MM.
# # """
# # type FitDirichletMultinomial{T <: Real} <: DistributionStat{VectorInput}
# #     value::Ds.DirichletMultinomial{T}
# #     suffstats::DirichletMultinomialStats
# #     weight::EqualWeight
# #     function FitDirichletMultinomial(p::Integer, wt::Weight = EqualWeight())
# #         new(Ds.DirichletMultinomial(1, p), EqualWeight())
# #     end
# # end
#
#
#
#
# #---------------------------------------------------------------------# MvNormal
# type FitMvNormal{W<:Weight} <: DistributionStat{VectorInput}
#     value::Ds.MvNormal
#     cov::CovMatrix{W}
# end
# function FitMvNormal(p::Integer, wgt::Weight = EqualWeight())
#     FitMvNormal(Ds.MvNormal(zeros(p), eye(p)), CovMatrix(p, wgt))
# end
# nobs(o::FitMvNormal) = nobs(o.cov)
# Base.std(d::FitMvNormal) = sqrt.(var(d))  # No std() method from Distributions?
# _fit!{T<:Real}(o::FitMvNormal, y::AVec{T}, γ::Float64) = _fit!(o.cov, y, γ)
# function value(o::FitMvNormal)
#     c = cov(o.cov)
#     if isposdef(c)
#         o.value = Ds.MvNormal(mean(o.cov), c)
#     else
#         warn("Covariance not positive definite.  More data needed.")
#     end
# end
# updatecounter!(o::FitMvNormal, n2::Int = 1) = updatecounter!(o.cov, n2)
# weight(o::FitMvNormal, n2::Int = 1) = weight(o.cov, n2)
#
#
#
# #---------------------------------------------------------------------# convenience constructors
# for nm in [:FitBeta, :FitGamma, :FitLogNormal, :FitNormal]
#     eval(parse("""
#         function $nm{T<:Real}(y::AVec{T}, wgt::Weight = EqualWeight())
#             o = $nm(wgt)
#             fit!(o, y)
#             o
#         end
#     """))
# end
#
# function FitCauchy{T<:Real}(y::AVec{T}, wgt::Weight = LearningRate())
#     o = FitCauchy(wgt)
#     fit!(o, y)
#     o
# end
#
# for nm in [:FitMultinomial, :FitMvNormal, :FitDirichletMultinomial]
#     eval(parse("""
#         function $nm{T<:Real}(y::AMat{T}, wgt::Weight = EqualWeight())
#             o = $nm(size(y, 2), wgt)
#             fit!(o, y)
#             o
#         end
#     """))
# end
#
# for nm in[:Beta, :Categorical, :Cauchy, :Gamma, :LogNormal, :Normal, :Multinomial, :MvNormal]
#     eval(parse("""
#         fitdistribution(::Type{Ds.$nm}, args...) = Fit$nm(args...)
#     """))
# end
#
#
#
# #--------------------------------------------------------------# fitdistribution docs
# """
# Estimate the parameters of a distribution.
#
# ```julia
# using Distributions
# # Univariate distributions
# o = fitdistribution(Beta, y)
# o = fitdistribution(Categorical, y)  # ignores Weight
# o = fitdistribution(Cauchy, y)
# o = fitdistribution(Gamma, y)
# o = fitdistribution(LogNormal, y)
# o = fitdistribution(Normal, y)
# mean(o)
# var(o)
# std(o)
# params(o)
#
# # Multivariate distributions
# o = fitdistribution(Multinomial, x)
# o = fitdistribution(MvNormal, x)
# mean(o)
# var(o)
# std(o)
# cov(o)
# ```
# """
# fitdistribution
