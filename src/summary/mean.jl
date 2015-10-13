#-------------------------------------------------------# Type and Constructors
"Univariate mean."
type Mean{W <: Weighting} <: OnlineStat
    μ::Float64
    n::Int
    weighting::W
end

function Mean{T<:Real}(y::AVec{T}, wgt::Weighting = default(Weighting))
    o = Mean(wgt)
    update!(o, y)
    o
end

Mean(wgt::Weighting = default(Weighting)) = Mean(0., 0, wgt)


#-----------------------------------------------------------------------# state
"Corresponding names to `state`"
statenames(o::Mean) = [:μ, :nobs]

"Current state of the model"
state(o::Mean) = Any[mean(o), nobs(o)]

Base.mean(o::Mean) = o.μ
Base.sum(o::Mean) = o.μ * o.n

center(o::Mean, y::Float64) = y - mean(o)
center!(o::Mean, y::Float64) = (update!(o, y); center(o, y))
uncenter(o::Mean, y::Float64) = y + mean(o)

#---------------------------------------------------------------------# update!

function update!(o::Mean, y::Float64, γ::Float64 = weight(o))
    o.μ = smooth(o.μ, y, γ)
    o.n += 1
    return
end

function updatebatch!(o::Mean, y::AVecF)
    n2 = length(y)
    o.μ = smooth(o.μ, mean(y), weight(o, n2))
    o.n += n2
    return
end

#------------------------------------------------------------------------# Base
function Base.empty!(o::Mean)
    o.μ = 0.
    o.n = 0
    return
end

function Base.merge!(o1::Mean, o2::Mean)
    λ = mergeweight(o1, o2)
    o1.μ = smooth(o1.μ, o2.μ, λ)
    o1.n += nobs(o2)
    o1
end
