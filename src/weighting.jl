

export ExponentialWeighting,
			 smooth

# NOTE: i put this here just so it's easy to review in a single file.. should be moved elsewhere... weighting.jl?
# NOTE: we call weight with n1 = "# old obs" and n2 = "# new obs"
abstract Weighting
weight(obj::OnlineStat, numUpdates::Int = 1) = weight(obj.weighting, nobs(obj), numUpdates)

immutable EqualWeighting <: Weighting end
weight(w::EqualWeighting, n1::Int, n2::Int) = n1 > 0 || n2 > 0 ? Float64(n2 / (n1 + n2)) : 1.0


immutable ExponentialWeighting <: Weighting
    λ::Float64
end
ExponentialWeighting(lookback::Int) = ExponentialWeighting(Float64(2 / (lookback + 1)))           # creates an exponential weighting with a lookback window of approximately "lookback" observations
weight(w::ExponentialWeighting, n1::Int, n2::Int) = max(weight(EqualWeighting(), n1, n2), w.λ)    # uses equal weighting until we collect enough observations... then uses exponential weighting


smooth{T}(avg::T, v::T, λ::Float64) = λ * v + (1 - λ) * avg
