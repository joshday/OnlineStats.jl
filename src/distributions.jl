#--------------------------------------------------------------# FitDistribution
type FitDistribution{D <: Ds.Distribution{Ds.Univariate}, W <: Weight} <: OnlineStat
    value::D
    # "sufficient statistics"
    var::Variance{W}
    quant::QuantileMM{W}
    mat::MatF
    vec::Vector{Int}

    weight::W
    n::Int
    nup::Int
end
function FitDistribution{D<:Ds.Distribution{Ds.Univariate}}(
        d::Type{D}, wgt::Weight = EqualWeight()
    )
    FitDistribution(d(), Variance(wgt), QuantileMM(wgt), zeros(1, 1), zeros(Int, 1), wgt, 0, 0)
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
    nothing
end
function fitbatch!{T<:Real}(o::FitDistribution, y::AVec{T})
    γ = weight!(o, length(y))
    fitdistbatch!(o, y, γ)
    nothing
end
Base.mean(o::FitDistribution) = mean(value(o))
Base.var(o::FitDistribution) = var(value(o))
Base.std(o::FitDistribution) = std(value(o))
Ds.params(o::FitDistribution) = Ds.params(value(o))
Ds.ncategories(o::FitDistribution) = Ds.ncategories(value(o))
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
    fit!(o.var, y)
end
function value(o::FitDistribution{Ds.Beta})
    m = mean(o.var)
    v = var(o.var)
    α = m * (m * (1 - m) / v - 1)
    β = (1 - m) * (m * (1 - m) / v - 1)
    try o.value = Ds.Beta(α, β) end
end


#------------------------------------------------------------------# Categorical
Ds.Categorical() = Ds.Categorical(1)
function fitdist!(o::FitDistribution{Ds.Categorical}, y::Integer, γ::Float64)
    if y <= length(o.vec)
        o.vec[y] += 1
    else
        addn = y - length(o.vec)
        append!(o.vec, zeros(Int, addn))
        o.vec[y] += 1
    end
end
function value(o::FitDistribution{Ds.Categorical})
    o.value = Ds.Categorical(o.vec / sum(o.vec))
end


#-----------------------------------------------------------------------# Cauchy
function fitdist!(o::FitDistribution{Ds.Cauchy}, y::Real, γ::Float64)
    fit!(o.quant, y)
end
function fitdistbatch!{T<:Real}(o::FitDistribution{Ds.Cauchy}, y::AVec{T}, γ::Float64)
    fitbatch!(o.quant, y)
end
function value(o::FitDistribution{Ds.Cauchy})
    o.value = Ds.Cauchy(o.quant.value[2], 0.5 * (o.quant.value[3] - o.quant.value[1]))
end


#------------------------------------------------------------------------# Gamma
# method of moments, look at Distributions for MLE
function fitdist!(o::FitDistribution{Ds.Gamma}, y::Real, γ::Float64)
    fit!(o.var, y)
end
function value(o::FitDistribution{Ds.Gamma})
    m = mean(o.var)
    v = var(o.var)
    θ = v / m
    α = m / θ
    if nobs(o) > 1
        o.value = Ds.Gamma(α, θ)
    end
end


#-----------------------------------------------------------------------# LogNormal
function fitdist!(o::FitDistribution{Ds.LogNormal}, y::Real, γ::Float64)
    fit!(o.var, log(y))
end
function value(o::FitDistribution{Ds.LogNormal})
    if nobs(o) > 1
        o.value = Ds.LogNormal(mean(o.var), std(o.var))
    end
end


#-----------------------------------------------------------------------# Normal
function fitdist!(o::FitDistribution{Ds.Normal}, y::Real, γ::Float64)
    fit!(o.var, y)
end
value(o::FitDistribution{Ds.Normal}) = (o.value = Ds.Normal(mean(o.var), std(o.var)))




#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
#------------------------------------------------------------# FitMvDistribution
#------------------------------------------------------------------------------#
#------------------------------------------------------------------------------#
type FitMvDistribution{D <: Ds.Distribution{Ds.Multivariate}, W <: Weight} <: OnlineStat
    value::D
    suff::CovMatrix{W}
    weight::W
    n::Int
    nup::Int
end
function FitMvDistribution{D<:Ds.Distribution{Ds.Multivariate}}(
        d::Type{D}, p::Integer, wgt::Weight = EqualWeight()
    )
    FitMvDistribution(_default(d, p), CovMatrix(p, wgt), wgt, 0, 0)
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
    if n_updates(o) == 1
        o.value = Ds.Multinomial(sum(y), y / sum(y))
    elseif n_updates(o) > 1
        @assert sum(y) == o.value.n "new observation has a different `n`"
        @assert length(y) == length(o.value.p) "new observation has different `p`"
    end
    fit!(o.suff, y)
end
function value(o::FitMvDistribution{Ds.Multinomial})
    m = mean(o.suff)
    o.value = Ds.Multinomial(round(Int, sum(m)), m / sum(m))
end


#---------------------------------------------------------------------# MvNormal
_default(::Type{Ds.MvNormal}, p::Integer) = Ds.MvNormal(zeros(p), diagm(ones(p)))
function fitdist!{D<:Ds.MvNormal, T<:Real}(o::FitMvDistribution{D}, y::AVec{T}, γ::Float64)
    fit!(o.suff, y)
end
function value{D<:Ds.MvNormal}(o::FitMvDistribution{D})
    c = cov(o.suff)
    if isposdef(c)
        o.value = Ds.MvNormal(mean(o.suff), c)
    end
end
