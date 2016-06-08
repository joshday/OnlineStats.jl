#----------------------------------------------------------------------------# Weight
abstract Weight
abstract BatchWeight <: Weight  # only BatchWeight types work for fitting by batch
abstract StochasticWeight <: BatchWeight


#-----------------------------------------------------------------------# EqualWeight
"""
One of the `Weight` types.  Observations are weighted equally.  For analytical
updates, the online algorithm will give results equal to the offline version.

- `EqualWeight()`
"""
type EqualWeight <: BatchWeight
    nobs::Int
    EqualWeight() = new(0)
    EqualWeight(n::Int) = new(n)
end


#-----------------------------------------------------------------# ExponentialWeight
"""
One of the `Weight` types.  Updates are performed with a constant weight
`λ = 2 / (1 + lookback)`.

- `ExponentialWeight(λ::Float64)`
- `ExponentialWeight(lookback::Int)`
"""
type ExponentialWeight <: Weight
    nobs::Int
    λ::Float64
    function ExponentialWeight(λ::Real = 1.0)
            @assert 0 <= λ <= 1
            new(0, λ)
    end
    ExponentialWeight(lookback::Integer) = ExponentialWeight(2.0 / (lookback + 1))
end


#----------------------------------------------------------------# BoundedEqualWeight
"""
One of the `Weight` types.  Uses `EqualWeight` until reaching `λ = 2 / (1 + lookback)`,
then weights are held constant.

- `BoundedEqualWeight(λ::Float64)`
- `BoundedEqualWeight(lookback::Int)`
"""
type BoundedEqualWeight <: Weight
    nobs::Int
    λ::Float64
    function BoundedEqualWeight(λ::Real = 1.0)
            @assert 0 <= λ <= 1
            new(0, λ)
    end
    BoundedEqualWeight(lookback::Integer) = BoundedEqualWeight(2.0 / (lookback + 1))
end


#----------------------------------------------------------------------# LearningRate
"""
One of the `Weight` types.  It's primary use is for the OnlineStats that use stochastic
approximation (`StatLearn`, `QuantReg`, `QuantileMM`, `QuantileSGD`, `NormalMix`, and
`KMeans`).  The weight at update `t` is `1 / t ^ r`.  When weights reach `λ`, they are
held consant.  Compare to `LearningRate2`.

- `LearningRate(r = 0.5, λ = 0.0)`
"""
type LearningRate <: StochasticWeight
    nobs::Int
    nups::Int
    r::Float64
    λ::Float64
    function LearningRate(r::Real = 0.5, λ::Real = 0.0)
        @assert 0 < r < 1
        @assert λ > 0
        new(0, 0, r, λ)
    end
end


#---------------------------------------------------------------------# LearningRate2
"""
One of the `Weight` types.  It's primary use is for the OnlineStats that use stochastic
approximation (`StatLearn`, `QuantReg`, `QuantileMM`, `QuantileSGD`, `NormalMix`, and
`KMeans`).  The weight at update `t` is `1 / (1 + c * (t - 1))`.  When weights reach
`λ`, they are held consant.  Compare to `LearningRate`.

- `LearningRate2(c = 0.5, λ = 0.0)`
"""
type LearningRate2 <: StochasticWeight
    nobs::Int
    nups::Int
    c::Float64
    λ::Float64
    LearningRate2(c::Real = 0.5, λ = 0.0) = new(0, 0, c, λ)
end


#---------------------------------------------------------------------------# methods
StatsBase.nobs(w::Weight) = w.nobs
nups(w::StochasticWeight) = w.nups

# increase nobs by the number of new observations
updatecounter!(w::Weight, n2::Int = 1)              = (w.nobs += n2)
updatecounter!(w::StochasticWeight, n2::Int = 1)    = (w.nobs += n2; w.nups += 1)
updatecounter!(o::OnlineStat, n2::Int = 1) = updatecounter!(o.weight, n2)

# Get weight for update of size n2, typically immediately after updatecounter!
weight(w::EqualWeight, n2::Int = 1)         = n2 / w.nobs
weight(w::BoundedEqualWeight, n2::Int = 1)  = max(w.λ, n2 / w.nobs)
weight(w::ExponentialWeight, n2::Int = 1)   = w.λ
weight(w::LearningRate, n2::Int = 1)        = max(w.λ, exp(-w.r * log(w.nups)))
weight(w::LearningRate2, n2::Int = 1)       = max(w.λ, 1.0 / (1.0 + w.c * (w.nups - 1)))
weight(o::OnlineStat, n2::Int = 1) = weight(o.weight, n2)
