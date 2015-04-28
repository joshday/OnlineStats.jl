abstract Weighting

weighting(o) = o.weighting
weight(o::OnlineStat, numUpdates::Int = 1) = weight(weighting(o), nobs(o), numUpdates)


smooth{T}(avg::T, v::T, λ::Float64) = λ * v + (1 - λ) * avg


#---------------------------------------------------------------------------#

immutable EqualWeighting <: Weighting end

@compat weight(w::EqualWeighting, n1::Int, n2::Int) =
    n1 > 0 || n2 > 0 ? Float64(n2 / (n1 + n2)) : 1.0


immutable ExponentialWeighting <: Weighting
    λ::Float64
end
@compat ExponentialWeighting(lookback::Int) = ExponentialWeighting(Float64(2 / (lookback + 1)))           # creates an exponential weighting with a lookback window of approximately "lookback" observations
weight(w::ExponentialWeighting, n1::Int, n2::Int) = max(weight(EqualWeighting(), n1, n2), w.λ)    # uses equal weighting until we collect enough observations... then uses exponential weighting


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


#---------------------------------------------------------------------------#


const DEFAULT_WEIGHTING = EqualWeighting()
