
#-------------------------------------------------------# Type and Constructors
type Var{W<:Weighting} <: ScalarStat
    μ::Float64
    biasedvar::Float64    # BIASED variance (makes for easier update)
    n::Int64
    weighting::W
end


function Var{T <: Real}(y::Vector{T}, wgt::Weighting = DEFAULT_WEIGHTING)
    o = Var(wgt)
    update!(o, y)  # apply the weighting scheme, as opposed to initializing with classic variance
    o
end

Var(y::Float64, wgt::Weighting = DEFAULT_WEIGHTING) = Var([y], wgt)
Var(wgt::Weighting = DEFAULT_WEIGHTING) = Var(0., 0., 0, wgt)


#-----------------------------------------------------------------------# state

statenames(o::Var) = [:μ, :σ², :nobs]
state(o::Var) = [mean(o), var(o), nobs(o)]

Base.mean(o::Var) = o.μ
Base.var(o::Var) = (n = nobs(o); (n < 2 ? 0. : o.biasedvar * n / (n - 1)))

#---------------------------------------------------------------------# update!


function update!(o::Var, y::Float64)
    n = nobs(o)
    λ = weight(o)
    μ = mean(o)

    o.μ = smooth(μ, y, λ)
    o.biasedvar = smooth(o.biasedvar, (y - μ) * (y - mean(o)), λ)
    o.n += 1
    return
end


#------------------------------------------------------------------------# Base

Base.copy(o::Var) = Var(o.μ, o.biasedvar, o.n, o.weighting)

# NOTE:
function Base.empty!(o::Var)
    o.μ = 0.
    o.biasedvar = 0.
    o.n = 0
    return
end

function Base.merge!(o1::Var, o2::Var)
    λ = mergeweight(o1, o2)
    o1.μ = smooth(o1.μ, o2.μ, λ)
    o1.biasedvar = smooth(o1.biasedvar, o2.biasedvar, λ)
    o1.n += nobs(o2)
    o1
end



