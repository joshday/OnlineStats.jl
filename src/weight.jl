#----------------------------------------------------------------------------# Weight
abstract Weight
abstract BatchWeight <: Weight  # only BatchWeight types work for fitting by batch
abstract StochasticWeight <: BatchWeight

#-----------------------------------------------------------------------# EqualWeight
"""
`EqualWeight()`.  All observations weighted equally.
"""
type EqualWeight <: BatchWeight
    nobs::Int
    EqualWeight() = new(0)
end

#-----------------------------------------------------------------# ExponentialWeight
"""
`ExponentialWeight(λ::Float64)`, `ExponentialWeight(lookback::Int)`

Weights are held constant at `λ = 2 / (1 + lookback)`.
"""
immutable ExponentialWeight <: Weight
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
`BoundedEqualWeight(λ::Float64)`, `BoundedEqualWeight(lookback::Int)`

Use equal weights until reaching `λ = 2 / (1 + lookback)`, then hold constant.
"""
immutable BoundedEqualWeight <: Weight
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
`LearningRate(r = 0.6, λ = 0.0)`.

Weight at update `t` is `1 / t ^ r`.  When weights reach `minstep`, hold weights constant.  Compare to `LearningRate2`.
"""
type LearningRate <: StochasticWeight
    nobs::Int
    nups::Int
    r::Float64
    λ::Float64
    LearningRate(r::Real = 0.6, λ::Real = 0.0) = new(0, 0, r, λ)
end


#---------------------------------------------------------------------# LearningRate2
"""
`LearningRate2(γ, c = 0.5, λ = 0.0)`.

Weight at update `t` is `1 / (1 + c * (t - 1))`.  When weights reach `minstep`, hold weights constant.  Compare to `LearningRate`.
"""
type LearningRate2 <: StochasticWeight
    nobs::Int
    nups::Int
    c::Float64
    λ::Float64
    LearningRate2(γ::Real, c::Real = 0.5, λ = 0.0) = new(c, λ, 0, 0)
end



#---------------------------------------------------------------------------# methods
StatsBase.nobs(w::Weight) = w.nobs
nups(w::StochasticWeight) = w.nups

# increase nobs by the number of new observations
updatecounter!(w::Weight, n2::Int = 1)              = (w.nobs += n2)
updatecounter!(w::StochasticWeight, n2::Int = 1)    = (w.nobs += n2; w.nups += 1)
updatecounter!(o::OnlineStat, n2::Int = 1) = updatecounter!(o.weight, n2)

# After updatecounter!, get the weight
weight(w::EqualWeight, n2::Int = 1)         = n2 / w.nobs
weight(w::BoundedEqualWeight, n2::Int = 1)  = max(w.λ, n2 / w.nobs)
weight(w::ExponentialWeight, n2::Int = 1)   = w.λ
weight(w::LearningRate, n2::Int = 1)        = max(w.λ, exp(-w.r * log(w.nups)))
weight(w::LearningRate2, n2::Int = 1)       = max(w.λ, 1.0 / (1.0 + w.c * (w.nups - 1)))
weight(o::OnlineStat, n2::Int = 1) = weight(o.weight, n2)


# For onlinestats that don't have/need a weight
updatecounter!(o::WeightlessOnlineStat, n2::Int = 1) = (o.nobs += n2)
weight(o::WeightlessOnlineStat, n2::Int = 1) = 0.0
