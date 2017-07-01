nobs(w::Weight) = OnlineStatsBase.nobs(w)
#-------------------------------------------------------------------------# EqualWeight
"""
```julia
EqualWeight()
```
- Equally weighted observations
- Singleton weight at observation `t` is `γ = 1 / t`
"""
mutable struct EqualWeight <: Weight
    nobs::Int
    nups::Int
    EqualWeight() = new(0, 0)
end
weight(w::EqualWeight, n2::Int = 1) = n2 / w.nobs
#-------------------------------------------------------------------------# ExponentialWeight
"""
```julia
ExponentialWeight(λ::Real = 0.1)
ExponentialWeight(lookback::Integer)
```
- Exponentially weighted observations (constant)
- Singleton weight at observation `t` is `γ = λ`
"""
mutable struct ExponentialWeight <: Weight
    λ::Float64
    nobs::Int
    nups::Int
    ExponentialWeight(λ::Real = 0.1) = new(λ, 0, 0)
    ExponentialWeight(lookback::Integer) = new(2 / (lookback + 1), 0, 0)
end
weight(w::ExponentialWeight, n2::Int = 1) = w.λ
#-------------------------------------------------------------------------# BoundedEqualWeight
"""
```julia
BoundedEqualWeight(λ::Real = 0.1)
BoundedEqualWeight(lookback::Integer)
```
- Use EqualWeight until threshold `λ` is hit, then hold constant.
- Singleton weight at observation `t` is `γ = max(1 / t, λ)`
"""
mutable struct BoundedEqualWeight <: Weight
    λ::Float64
    nobs::Int
    nups::Int
    BoundedEqualWeight(λ::Real = 0.1) = new(λ, 0, 0)
    BoundedEqualWeight(lookback::Integer) = new(2 / (lookback + 1), 0, 0)
end
weight(w::BoundedEqualWeight, n2::Int = 1) = max(n2 / w.nobs, w.λ)
#-------------------------------------------------------------------------# LearningRate
"""
```julia
LearningRate(r = .6, λ = 0.0)
```
- Mainly for stochastic approximation types (`QuantileSGD`, `QuantileMM` etc.)
- Decreases at a "slow" rate until threshold `λ` is reached
- Singleton weight at observation `t` is `γ = max(1 / t ^ r, λ)`
"""
mutable struct LearningRate <: Weight
    λ::Float64
    r::Float64
    nobs::Int
    nups::Int
    LearningRate(r::Real = .6, λ::Real = 0.0) = new(λ, r, 0, 0)
end
weight(w::LearningRate, n2::Int = 1) = max(w.λ, exp(-w.r * log(w.nups)))
#-------------------------------------------------------------------------# LearningRate2
"""
```julia
LearningRate2(c = .5, λ = 0.0)
```
- Mainly for stochastic approximation types (`QuantileSGD`, `QuantileMM` etc.)
- Decreases at a "slow" rate until threshold `λ` is reached
- Singleton weight at observation `t` is `γ = max(inv(1 + c * (t - 1), λ)`
"""
mutable struct LearningRate2 <: Weight
    c::Float64
    λ::Float64
    nobs::Int
    nups::Int
    LearningRate2(c::Real = 0.5, λ::Real = 0.0) = new(c, λ, 0, 0)
end
function weight(w::LearningRate2, n2::Int = 1)
    max(w.λ, 1.0 / (1.0 + w.c * (w.nups - 1)))
end
#-------------------------------------------------------------------------# HarmonicWeight
"""
```julia
HarmonicWeight(a = 10.0)
```
- Decreases at a slow rate
- Singleton weight at observation `t` is `γ = a / (a + t - 1)`
"""
mutable struct HarmonicWeight <: Weight
    a::Float64
    nobs::Int
    nups::Int
    function HarmonicWeight(a::Float64 = 10.0)
        a > 0 || throw(ArgumentError("`a` must be greater than 0"))
        new(a, 0, 0)
    end
end
function weight(w::HarmonicWeight, n2::Int = 1)
    w.a / (w.a + w.nobs - 1)
end
#-------------------------------------------------------------------------# McclainWeight
# Link with many weighting schemes:
# http://castlelab.princeton.edu/ORF569papers/Powell%20ADP%20Chapter%206.pdf
"""
```julia
McclainWeight(ᾱ = 0.1)
```
- "smoothed" version of `BoundedEqualWeight`
- weights asymptotically approach `ᾱ`
- Singleton weight at observation `t` is `γ(t-1) / (1 + γ(t-1) - ᾱ)`
"""
mutable struct McclainWeight <: Weight
    ᾱ::Float64
    last::Float64
    nobs::Int
    nups::Int
    function McclainWeight(ᾱ = .1)
        0 < ᾱ < 1 || throw(ArgumentError("value must be between 0 and 1"))
        new(ᾱ, 1.0, 0, 0)
    end
end
fields_to_show(w::McclainWeight) = [:ᾱ, :nobs]
function weight(w::McclainWeight, n2::Int = 1)
    w.nups == 1 && return 1.0
    w.last = w.last / (1 + w.last - w.ᾱ)
end
#-----------------------------------------------------------------------# Plot recipe
@recipe function f(wt::Weight; nobs=50)
    xlab --> "Number of Observations"
    ylab --> "Weight Value"
    label --> name(wt)
    ylim --> (0, 1)
    w --> 2
    W = deepcopy(wt)
    v = zeros(nobs)
    for i in eachindex(v)
        updatecounter!(W)
        v[i] = weight(W)
    end
    v
end
