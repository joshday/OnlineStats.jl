
#-------------------------------------------------------# Type and Constructors
type Var{W<:Weighting} <: OnlineStat
    μ::Float64
    biasedvar::Float64    # BIASED variance (makes for easier update)
    n::Int64
    weighting::W
end


function Var{T <: Real}(y::Vector{T}, wgt::Weighting = default(Weighting))
    o = Var(wgt)
    update!(o, y)  # apply the weighting scheme, as opposed to initializing with classic variance
    o
end

Var(y::Float64, wgt::Weighting = default(Weighting)) = Var([y], wgt)
Var(wgt::Weighting = default(Weighting)) = Var(0., 0., 0, wgt)


#-----------------------------------------------------------------------# state

statenames(o::Var) = [:μ, :σ², :nobs]
state(o::Var) = Any[mean(o), var(o), nobs(o)]

Base.mean(o::Var) = o.μ
Base.var(o::Var) = (n = nobs(o); (n < 2 ? 0. : o.biasedvar * n / (n - 1)))
Base.std(o::Var) = sqrt(var(o))

#-----------------------------------------------------------------------# normalize

if0then1(x::Float64) = (x == 0. ? 1. : x)

normalize(o::Var, y::Float64) = (y - mean(o)) / if0then1(std(o))
denormalize(o::Var, y::Float64) = y * std(o) + mean(o)

function normalize!(o::Var, y::Float64)
    update!(o, y)
    normalize(o, y)
end

normalize!(os::Vector{Var}, y::VecF) = map(normalize!, os, y)

#---------------------------------------------------------------------# update!


function update!(o::Var, y::Float64)
    λ = weight(o)
    μ = mean(o)

    o.μ = smooth(μ, y, λ)
    o.biasedvar = smooth(o.biasedvar, (y - μ) * (y - mean(o)), λ)
    o.n += 1
    return
end

# Base.copy(o::Var) = Var(o.μ, o.biasedvar, o.n, o.weighting)

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



