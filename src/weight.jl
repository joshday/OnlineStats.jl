#--------------------------------------------------------------------# Weight
abstract type Weight end
Base.show(io::IO, w::Weight) = print(io, name(w) * "(nobs = $(w.nobs)): ")
function Base.:(==){T <: Weight}(w1::T, w2::T)
    nms = fieldnames(w1)
    equal = true
    for nm in nms
        equal = getfield(w1, nm) == getfield(w2, nm)
    end
    return equal
end

default(::Type{Weight}, o::OnlineStat) = EqualWeight()
function default(w::Type{Weight}, t::Tuple)
    weight = default(Weight, t[1])
    all(isa.(default.(Weight, t), typeof(weight))) ||
        throw(ArgumentError("Default weights differ.  Weight must be specified"))
    weight
end

nobs(w::Weight) = w.nobs
nups(w::Weight) = w.nups
updatecounter!(w::Weight, n2::Int = 1) = (w.nobs += n2; w.nups += 1;)
weight!(w::Weight, n2::Int = 1) = (updatecounter!(w, n2); weight(w, n2))

#--------------------------------------------------------------------# EqualWeight
"""
    EqualWeight()

- Equally weighted observations
- Singleton weight at observation `t` is `γ = 1 / t`
"""
mutable struct EqualWeight <: Weight
    nobs::Int
    nups::Int
    EqualWeight() = new(0, 0)
end
weight(w::EqualWeight, n2::Int = 1) = n2 / w.nobs

#--------------------------------------------------------------------# ExponentialWeight
"""
    ExponentialWeight(λ::Real = 0.1)
    ExponentialWeight(lookback::Integer)

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

#--------------------------------------------------------------------# BoundedEqualWeight
"""
BoundedEqualWeight(λ::Real = 0.1)
BoundedEqualWeight(lookback::Integer)

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

#--------------------------------------------------------------------# LearningRate
"""
    LearningRate(r = .6, λ = 0.0)

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

#--------------------------------------------------------------------# LearningRate2
"""
    LearningRate2(c = .5, λ = 0.0)

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
