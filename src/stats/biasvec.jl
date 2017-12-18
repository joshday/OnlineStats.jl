"""
    BiasVec(x, bias = 1.0)

LightWeight wrapper of a vector which adds a "bias" term at the end.

# Example

    OnlineStats.BiasVec(rand(5), 10)
"""
struct BiasVec{T, A <: VectorOb} <: AbstractVector{T}
    x::A
    bias::T
end
# typeof(x[1]) instead of eltype -> allow tuples
BiasVec(x, bias = 1.0) = BiasVec{typeof(x[1]), typeof(x)}(x, bias)

Base.length(v::BiasVec) = length(v.x) + 1

Base.size(v::BiasVec) = (length(v), )

Base.getindex(v::BiasVec, i::Int) = i > length(v.x) ? v.bias : v.x[i]

Base.IndexStyle(::Type{<:BiasVec}) = IndexLinear()