abstract Weight
nobs(w::Weight) = w.n
weight!(o::OnlineStat, n2::Int = 1) = weight!(o.weight, n2)
weight_noret!(o::OnlineStat, n2::Int = 1) = weight_noret!(o.weight, n2)


"""
`EqualWeight()`.  All observations weighted equally.
"""
type EqualWeight <: Weight
    n::Int
    EqualWeight() = new(0)
end
weight!(w::EqualWeight, n2::Int = 1)        = (w.n += n2; n2 / w.n)
weight_noret!(w::EqualWeight, n2::Int = 1)  = (w.n += n2)


"""
`ExponentialWeight(λ::Float64)`, `ExponentialWeight(lookback::Int)`

Weights are held constant at `λ = 2 / (1 + lookback)`.
"""
type ExponentialWeight <: Weight
    λ::Float64
    n::Int
    function ExponentialWeight(λ::Real, n::Integer)
        @assert 0 <= λ <= 1
        new(λ, n)
    end
    ExponentialWeight(λ::Real = 1.0) = ExponentialWeight(λ, 0)
    ExponentialWeight(lookback::Integer) = ExponentialWeight(2.0 / (lookback + 1))
end
weight!(w::ExponentialWeight, n2::Int = 1)  = (w.n += n2; w.λ)
weight_noret!(w::ExponentialWeight, n2::Int = 1) = (w.n += n2)



"""
`BoundedExponentialWeight(λ::Float64)`, `BoundedExponentialWeight(lookback::Int)`

Use equal weights until reaching `λ = 2 / (1 + lookback)`, then hold constant.
"""
type BoundedExponentialWeight <: Weight
    λ::Float64
    n::Int
    function BoundedExponentialWeight(λ::Real, n::Integer)
        @assert 0 <= λ <= 1
        new(λ, n)
    end
    BoundedExponentialWeight(λ::Real = 1.0) = BoundedExponentialWeight(λ, 0)
    BoundedExponentialWeight(lookback::Integer) = BoundedExponentialWeight(2.0 / (lookback + 1))
end
weight!(w::BoundedExponentialWeight, n2::Int = 1)  = (w.n += n2; return max(n2 / w.n, w.λ))
weight_noret!(w::BoundedExponentialWeight, n2::Int = 1) = (w.n += n2)


"""
`LearningRate(r = 0.6; minstep = 0.0)`.

Weight at update `t` is `1 / t ^ r`.  When weights reach `minstep`, hold weights constant.  Compare to `LearningRate2`.
"""
type LearningRate <: Weight
    r::Float64
    minstep::Float64
    n::Int
    nups::Int
    LearningRate(r::Real = 0.6; minstep::Real = 0.0) = new(r, minstep, 0, 0)
end
function weight!(w::LearningRate, n2::Int = 1)
    w.n += n2
    w.nups += 1
    max(w.minstep, exp(-w.r * log(w.nups)))
end
weight_noret!(w::LearningRate, n2::Int = 1) = (w.n += n2; w.nups += 1)
nups(w::LearningRate) = w.nups


"""
`LearningRate2(γ, c = 1.0; minstep = 0.0)`.

Weight at update `t` is `γ / (1 + γ * c * t)`.  When weights reach `minstep`, hold weights constant.  Compare to `LearningRate`.
"""
type LearningRate2 <: Weight
    # Recommendation from http://research.microsoft.com/pubs/192769/tricks-2012.pdf
    γ::Float64
    c::Float64
    minstep::Float64
    n::Int
    nups::Int
    LearningRate2(γ::Real, c::Real = 1.0; minstep = 0.0) = new(γ, c, minstep, 0, 0)
end
function weight!(w::LearningRate2, n2::Int = 1)
    w.n += n2
    w.nups += 1
    max(w.minstep, w.γ / (1.0 + w.γ * w.c * w.nups))
end
weight_noret!(w::LearningRate2, n2::Int = 1) = (w.n += n2; w.nups += 1)
nups(w::LearningRate2) = w.nups

nups(o::OnlineStat) = nups(o.w)





# #----------------------------------------------------------------# WeightedOnlineStat
# """
# `WeightedOnlineStat(Mean)`
# """
# type WeightedOnlineStat{I <: Input}
#     o::OnlineStat{I}
#     wsum::Float64
# end
# function WeightedOnlineStat(o::OnlineStat)
#     @assert typeof(o.weight) == ExponentialWeight
#     WeightedOnlineStat(o, 0.0)
# end
# function WeightedOnlineStat(t::Type, args...)
#     WeightedOnlineStat(t(args..., ExponentialWeight()))
# end
#
# function Base.show(io::IO, o::WeightedOnlineStat)
#     printheader(io, "WeightedOnlineStat")
#     show(o.o)
# end
#
# value(w::WeightedOnlineStat) = value(w.o)
#
#
# # ScalarInput
# function fit!(o::WeightedOnlineStat{ScalarInput}, y::Real, w::Real)
#     @assert w > 0
#     o.wsum += w
#     o.o.weight.λ = w / o.wsum
#     fit!(o.o, y)
#     o
# end
# function fit!(o::WeightedOnlineStat{ScalarInput}, y::AVec, w::AVec)
#     @assert length(y) == length(w)
#     for i in eachindex(y)
#         fit!(o, y[i], w[i])
#     end
#     o
# end
#
# # VectorInput
# function fit!(o::WeightedOnlineStat{VectorInput}, y::AVec, w::Real)
#     @assert w > 0
#     o.wsum += w
#     o.o.weight.λ = w / o.wsum
#     fit!(o.o, y)
#     o
# end
# function fit!(o::WeightedOnlineStat{VectorInput}, y::AMat, w::AVec)
#     @assert size(y, 1) == length(w)
#     for i in eachindex(w)
#         fit!(o, row(y, i), w[i])
#     end
#     o
# end
#
# # XYInput
# function fit!(o::WeightedOnlineStat{XYInput}, x::AVec, y::Real, w::Real)
#     @assert w > 0
#     o.wsum += w
#     o.o.weight.λ = w / o.wsum
#     fit!(o.o, x, y)
#     o
# end
# function fit!(o::WeightedOnlineStat{XYInput}, x::AMat, y::AVec, w::AVec)
#     @assert length(y) == length(w)
#     for i in eachindex(w)
#         fit!(o, row(x, i), row(y, i), w[i])
#     end
#     o
# end
