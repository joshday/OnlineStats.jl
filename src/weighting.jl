abstract Weighting

weighting(o) = o.weighting
weight(o::OnlineStat, numUpdates::Int = 1) = weight(weighting(o), nobs(o), numUpdates)

default(::Type{Weighting}) = EqualWeighting()

#---------------------------------------------------------------------------#

smooth(avg, v, λ::Float64) = λ * v + (1 - λ) * avg

# More stable version?
# smooth{T}(avg::T, v::T, λ::Float64) = avg + λ * (v - avg)

# This removes garbage collection time when updating arrays
function smooth!(avg::AbstractVector, v::AbstractVector, λ::Float64)
    for i in 1:length(avg)
        avg[i] = smooth(avg[i], v[i], λ)
    end
end

function smooth!(avg::AbstractMatrix, v::AbstractMatrix, λ::Float64)
    n, p = size(avg)
    for j in 1:p, i in 1:n
        avg[i,j] = smooth(avg[i, j], v[i, j], λ)
    end
end

# For SGD, Online MM, Online EM, etc. (stochastic approximation methods)
# Perform the update: avg = avg + λ * grad
function addgradient!(avg::AbstractVector, grad::AbstractVector, λ::Float64)
    p = length(avg)
    for i in 1:p
        avg[i] = avg[i] + λ * grad[i]
    end
end

#---------------------------------------------------------------------------#
"""
### Equal Weighting
`EqualWeighting()`

All observations are weighted equally
"""
immutable EqualWeighting <: Weighting end

weight(w::EqualWeighting, n1::Int, n2::Int) =
    n1 > 0 || n2 > 0 ? Float64(n2 / (n1 + n2)) : 1.0

"""
### Exponential Weighting

`ExponentialWeighting(λ::Float64)`

`ExponentialWeighting(n::Int)`

Use equal weighting until step size reaches `λ = 1 / n`, then hold constant.
"""
immutable ExponentialWeighting <: Weighting
    λ::Float64

    # ensure λ stays between 0 and 1
    function ExponentialWeighting(λ::Float64)
    	@assert λ >= 0. && λ <= 1.
    	new(λ)
    end
end
# creates an exponential weighting with a lookback window of approximately "lookback" observations
ExponentialWeighting(lookback::Int) = ExponentialWeighting(Float64(2 / (lookback + 1)))
# uses equal weighting until we collect enough observations... then uses exponential weighting
weight(w::ExponentialWeighting, n1::Int, n2::Int) = max(weight(EqualWeighting(), n1, n2), w.λ)



#-----------------------------------------------------------------# LearningRate
"""
`LearningRate(;r = 1.0, s = 1.0, minstep = 0.0)`

Update weights are `max(minstep, γ_t)` where `γ_t = 1 / (1 + s * t) ^ r`
"""
type LearningRate <: Weighting
    r::Float64
    s::Float64
    minstep::Float64    # minimum step size
    t::Int64            # number of updates

    function LearningRate(;r::Real = 1.0, s::Real = 1.0, minstep::Real = 0.0)
        @assert 0 < r <= 1
        @assert s > 0
        new(Float64(r), Float64(s), Float64(minstep), 0)
    end
end
function weight(w::LearningRate, unused1 = 1, unused2 = 1)
    result = max(1.0 / (1.0 + w.s * w.t) ^ w.r, w.minstep)
    w.t += 1
    result
end


# #----------------------------------------------------------------------# ADAGRAD
# # This isn't a subtype of Weighting, since it only makes sense for SGD-like types
# type ADAGRAD
#     g0::Float64
#     g::VecF
# end
# function weight0(w::ADAGRAD, gᵢ::Float64)
#     w.g0 += gᵢ ^ 2
#     sqrt(w.g0)
# end
# function weight(w::ADAGRAD, gᵢ::Float64, i::Integer)
#     w.g[i] += gᵢ ^ 2
#     sqrt(w.g[i])
# end


#---------------------------------------------------------------------------#

# mergeweight will give the weighting λ for o1 for the following weighted avg:  (1 - λ) * o1 + λ * o2
function mergeweight(o1::OnlineStat, o2::OnlineStat)

	# for now, lets just throw an error if we mix and match weighting types
	@assert weighting(o1) == weighting(o2)

	n1 = adjusted_nobs(o1)
	n2 = adjusted_nobs(o2)
	n2 > 0 ? n2 / (n1 + n2) : 0.0
end

adjusted_nobs(o::OnlineStat) = adjusted_nobs(nobs(o), weighting(o))
adjusted_nobs(n::Int, w::EqualWeighting) = n
adjusted_nobs(n::Int, w::ExponentialWeighting) = min(n, 2 / w.λ - 1) # minimum of n and effective lookback window
