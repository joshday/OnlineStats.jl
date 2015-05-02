abstract Weighting

weighting(o) = o.weighting
weight(o::OnlineStat, numUpdates::Int = 1) = weight(weighting(o), nobs(o), numUpdates)

default(::Type{Weighting}) = EqualWeighting()

#---------------------------------------------------------------------------#

smooth{T}(avg::T, v::T, λ::Float64) = λ * v + (1 - λ) * avg

# This removes garbage collection time when updating arrays
function smooth!{T}(avg::Vector{T}, v::Vector{T}, λ::Float64)
    for i in 1:length(avg)
        avg[i] = smooth(avg[i], v[i], λ)
    end
end

function smooth!{T}(avg::Matrix{T}, v::Matrix{T}, λ::Float64)
    n, p = size(avg)
    for j in 1:p, i in 1:n
        avg[i,j] = smooth(avg[i, j], v[i, j], λ)
    end
end


#---------------------------------------------------------------------------#

immutable EqualWeighting <: Weighting end

@compat weight(w::EqualWeighting, n1::Int, n2::Int) =
    n1 > 0 || n2 > 0 ? Float64(n2 / (n1 + n2)) : 1.0


immutable ExponentialWeighting <: Weighting
    λ::Float64

    # ensure λ stays between 0 and 1
    function ExponentialWeighting(λ::Float64)
    	@assert λ >= 0. && λ <= 1.
    	new(λ)
    end
end
@compat ExponentialWeighting(lookback::Int) = ExponentialWeighting(Float64(2 / (lookback + 1)))           # creates an exponential weighting with a lookback window of approximately "lookback" observations
weight(w::ExponentialWeighting, n1::Int, n2::Int) = max(weight(EqualWeighting(), n1, n2), w.λ)    # uses equal weighting until we collect enough observations... then uses exponential weighting


#---------------------------------------------------------------------------# Stochastic
type StochasticWeighting
    r::Float64
    nb::Int64   # number of batches
    λ::Float64  # minimum step size
    function StochasticWeighting(r::Float64 = .51, λ::Float64 = 0.)
        @assert r > .5 && r <= 1
        @assert λ >= 0. && λ <= 1.
        new(r, 0, λ)
    end
end
@compat function weight!(w::StochasticWeighting)
    w.nb += 1
    max(Float64(w.nb) ^ -w.r, w.λ)
end


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

