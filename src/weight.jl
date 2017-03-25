#--------------------------------------------------------------------# Weight
abstract type Weight end
Base.show(io::IO, w::Weight) = print(io, name(w) * "( " * show_weight(w) * " )")
nextweight(w::Weight, n::Int, n2::Int, nups::Int) = weight(w, n + n2, n2, nups + 1)
weight(o::AbstractSeries, n2::Int = 1) = weight(o.weight, o.nobs, n2, o.nups)
nextweight(o::AbstractSeries, n2::Int = 1) = nextweight(o.weight, o.nobs, n2, o.nups)

#--------------------------------------------------------------------# EqualWeight
struct EqualWeight <: Weight end
show_weight(w::EqualWeight) = "γ = 1 / t"
weight(w::EqualWeight, n::Int, n2::Int, nups::Int) = n2 / n

#--------------------------------------------------------------------# ExponentialWeight
struct ExponentialWeight <: Weight
    λ::Float64
    ExponentialWeight(λ::Real = 0.1) = new(λ)
    ExponentialWeight(lookback::Integer) = new(2 / (lookback + 1))
end
show_weight(w::ExponentialWeight) = "γ = $(w.λ)"
weight(w::ExponentialWeight, n::Int, n2::Int, nups::Int) = w.λ

#--------------------------------------------------------------------# BoundedEqualWeight
struct BoundedEqualWeight <: Weight
    λ::Float64
    BoundedEqualWeight(λ::Real = 0.1) = new(λ)
    BoundedEqualWeight(lookback::Integer) = new(2 / (lookback + 1))
end
show_weight(w::BoundedEqualWeight) = "γ = max(1 / t, $(w.λ))"
weight(w::BoundedEqualWeight, n::Int, n2::Int, nups::Int) = max(n2 / n, λ)

#--------------------------------------------------------------------# LearningRate
struct LearningRate <: Weight
    λ::Float64
    r::Float64
    LearningRate(r::Real = .6, λ::Real = 0.0) = new(λ, r)
end
show_weight(w::LearningRate) = "γ = max(t ^ -$(w.r), $(w.λ))"
weight(w::LearningRate, n::Int, n2::Int, nups::Int) = max(w.λ, exp(-w.r * log(nups)))

#--------------------------------------------------------------------# LearningRate2
struct LearningRate2 <: Weight
    c::Float64
    λ::Float64
    LearningRate2(c::Real = 0.5, λ::Real = 0.0) = new(c, λ)
end
show_weight(w::LearningRate2) = "γ = max(inv(1 + c * (t - 1)), $(w.λ))"
function weight(w::LearningRate2, n::Int, n2::Int, nups::Int)
    max(w.λ, 1.0 / (1.0 + w.c * (nups - 1)))
end
