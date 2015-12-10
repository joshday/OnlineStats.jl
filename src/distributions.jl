typealias SufficientStats Union{Variance, QuantileMM, MatF, Vector{Int}}

#--------------------------------------------------------------# FitDistribution
type FitDistribution{D <: Ds.Distribution{Ds.Univariate}, W <: Weight} <: OnlineStat
    value::D
    suff::SufficientStats
    weight::W
    n::Int
    nup::Int
end
function FitDistribution{D<:Ds.Distribution{Ds.Univariate}}(
        d::Type{D}, wgt::Weight = EqualWeight()
    )
    FitDistribution(d(), _suff(d), wgt, 0, 0)
end
function FitDistribution{D<:Ds.Distribution{Ds.Univariate}, T<:Real}(
        d::Type{D}, y::AVec{T}, wgt::Weight = EqualWeight()
    )
    o = FitDistribution(d, wgt)
    fit!(o, y)
    o
end
function fit!(o::FitDistribution, y::Real)
    γ = weight!(o, 1)
    fitdist!(o, y, γ)
end
function fitbatch!{T<:Real}(o::FitDistribution, y::AVec{T})
    γ = weight!(o, length(y))
    fitdistbatch!(o, y, γ)
end
_suff{D <: Ds.Distribution}(::Type{D}) = Variance()  # default sufficient statistics
Base.mean(o::FitDistribution) = mean(o.value)
Base.var(o::FitDistribution) = var(o.value)
Base.std(o::FitDistribution) = std(o.value)
Ds.params(o::FitDistribution) = Ds.params(o.value)
function Base.show(io::IO, o::FitDistribution)
    printheader(io, "FitDistribution")
    print_value_and_nobs(io, o)
end


# Distributions based solely on mean
for d in [:Bernoulli, :Exponential, :Poisson]
    eval(parse(
        """
        function fitdist!(o::FitDistribution{Ds.$d}, y::Real, γ::Float64)
            θ = smooth(mean(o), Float64(y), γ)
            o.value = Ds.$d(θ)
            nothing
        end
        """
    ))
end


#-------------------------------------------------------------------------# Beta
# method of moments
function fitdist!(o::FitDistribution{Ds.Beta}, y::Real, γ::Float64)
    fit!(o.suff, y)
    m = mean(o.suff)
    v = var(o.suff)
    α = m * (m * (1 - m) / v - 1)
    β = (1 - m) * (m * (1 - m) / v - 1)
    try o.value = Ds.Beta(α, β) end
    nothing
end


#------------------------------------------------------------------# Categorical
Ds.Categorical() = Ds.Categorical(1)
_suff(::Type{Ds.Categorical}) = zeros(Int, 1)
function fitdist!(o::FitDistribution{Ds.Categorical}, y::Integer, γ::Float64)
    if y <= length(o.suff)
        o.suff[y] += 1
    else
        addn = y - length(o.suff)
        append!(o.suff, zeros(Int, addn))
        o.suff[y] += 1
    end
    o.value = Ds.Categorical(o.suff / sum(o.suff))
end


#-----------------------------------------------------------------------# Cauchy
_suff(::Type{Ds.Cauchy}) = QuantileMM()
function fitdist!(o::FitDistribution{Ds.Cauchy}, y::Real, γ::Float64)
    fit!(o.suff, y)
    try o.value = Ds.Cauchy(o.suff.value[2], o.suff.value[3] - o.suff.value[1]) end
end


#------------------------------------------------------------------------# Gamma
# method of moments, look at Distributions for MLE
function fitdist!(o::FitDistribution{Ds.Gamma}, y::Real, γ::Float64)
    fit!(o.suff, y)
    m = mean(o.suff)
    v = var(o.suff)
    θ = v / m
    α = m / θ
    if nobs(o) > 1
        o.value = Ds.Gamma(α, θ)
    end
    nothing
end


#-----------------------------------------------------------------------# LogNormal
function fitdist!(o::FitDistribution{Ds.LogNormal}, y::Real, γ::Float64)
    fit!(o.suff, log(y))
    if nobs(o) > 1
        o.value = Ds.LogNormal(mean(o.suff), std(o.suff))
    end
    nothing
end


#-----------------------------------------------------------------------# Normal
function fitdist!(o::FitDistribution{Ds.Normal}, y::Real, γ::Float64)
    fit!(o.suff, y)
    if nobs(o) > 1
        o.value = Ds.Normal(mean(o.suff), std(o.suff))
    end
    nothing
end


#--------------------------------------------------------------------# NormalMix
# typealias NormalMixture Ds.MixtureModel{Ds.Univariate, Ds.Continuous, Ds.Normal}
# _suff(::Type{NormalMixture}) = zeros(1, 1)
# function fitdist!(o::FitDistribution{NormalMixture}, y::Real, γ::Float64)
#     if n_updates(o) == 1
#         o.suff = MatF  # s_i for component j is o.suff[i, j]
#     end
# end



#------------------------------------------------------------------------------#
#------------------------------------------------------------# FitMvDistribution
type FitMvDistribution{D <: Ds.Distribution{Ds.Multivariate}, W <: Weight} <: OnlineStat
    value::D
    suff::CovMatrix
    weight::W
    n::Int
    nup::Int
end
function FitMvDistribution{D<:Ds.Distribution{Ds.Multivariate}}(
        d::Type{D}, p::Integer, wgt::Weight = EqualWeight()
    )
    FitMvDistribution(_default(d, p), CovMatrix(p), wgt, 0, 0)
end
function FitMvDistribution{D<:Ds.Distribution{Ds.Multivariate}, T<:Real}(
        d::Type{D}, y::AMat{T}, wgt::Weight = EqualWeight()
    )
    o = FitMvDistribution(d, size(y, 2), wgt)
    fit!(o, y)
    o
end
function fit!{T<:Real}(o::FitMvDistribution, y::AVec{T})
    γ = weight!(o, 1)
    fitdist!(o, y, γ)
end
Base.mean(o::FitMvDistribution) = mean(value(o))
Base.std(o::FitMvDistribution) = sqrt(var(o))
Base.var(o::FitMvDistribution) = var(value(o))
Base.cov(o::FitMvDistribution) = cov(value(o))
function Base.show(io::IO, o::FitMvDistribution)
    printheader(io, "FitMvDistribution")
    print_value_and_nobs(io, o)
end


#------------------------------------------------------------------# Multinomial
_default(::Type{Ds.Multinomial}, p::Integer) = Ds.Multinomial(1, ones(p) / p)
function fitdist!{T<:Real}(o::FitMvDistribution{Ds.Multinomial}, y::AVec{T}, γ::Float64)
    if n_updates(o) > 1
        @assert sum(y) == o.value.n "new observation has a different `n`"
        @assert length(y) == length(o.value.p) "new observation has different `p`"
    end
    fit!(o.suff, y)
    m = mean(o.suff)
    o.value = Ds.Multinomial(sum(y), m / sum(m))
    nothing
end

#---------------------------------------------------------------------# MvNormal
_default(::Type{Ds.MvNormal}, p::Integer) = Ds.MvNormal(zeros(p), diagm(ones(p)))
function fitdist!{D<:Ds.MvNormal, T<:Real}(o::FitMvDistribution{D}, y::AVec{T}, γ::Float64)
    fit!(o.suff, y)
    c = cov(o.suff)
    if isposdef(c)
        o.value = Ds.MvNormal(mean(o.suff), cov(o.suff))
    end
    nothing
end
