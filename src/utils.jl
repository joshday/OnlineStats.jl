#-----------------------------------------------------------------------# General
const Tup = Union{Tuple, NamedTuple}
const XY = Union{AbstractVector, Tup, Pair}
const VectorOb = Union{AbstractVector, Tup}
const TwoThings{T,S} = Union{Tuple{T,S}, Pair{T,S}, NamedTuple{names, Tuple{T,S}}} where names

smooth(a, b, γ) = a + γ * (b - a)

function smooth!(a, b, γ)
    for i in eachindex(a)
        a[i] = smooth(a[i], b[i], γ)
    end
end

function smooth_syr!(A::AbstractMatrix, x, γ::Number)
    for j in 1:size(A, 2), i in 1:j
        A[i, j] = smooth(A[i,j], x[i] * conj(x[j]), γ)
    end
end

_dot(x::AbstractVector, y::AbstractVector) = dot(x, y)
@generated function _dot(x::VectorOb, y::VectorOb)
    n = length(fieldnames(x))
    quote
        out = zero(promote_type(typeof(x[1]), typeof(y[1])))
        Base.Cartesian.@nexprs $n i-> (out += x[i] * y[i])
        out
    end
end

unbias(o) = nobs(o) / (nobs(o) - 1)

Statistics.std(o::OnlineStat; kw...) = sqrt.(var(o; kw...))

const ϵ = 1e-7

#-----------------------------------------------------------------------# BiasVec
"""
    BiasVec(x)

Lightweight wrapper of a vector which adds a "bias" term at the end.

# Example

    BiasVec(rand(5))
"""
struct BiasVec{T, A <: VectorOb} <: AbstractVector{T}
    x::A
    bias::T
end
BiasVec(x::AbstractVector{T}) where {T} = BiasVec(x, one(T))
BiasVec(x::Tup) = BiasVec(x, one(typeof(first(x))))

Base.length(v::BiasVec) = length(v.x) + 1
Base.size(v::BiasVec) = (length(v), )
Base.getindex(v::BiasVec, i::Int) = i > length(v.x) ? v.bias : v.x[i]
Base.IndexStyle(::Type{<:BiasVec}) = IndexLinear()

#-----------------------------------------------------------------------# fit!
# convenience methods.  deprecate?
fit!(o::OnlineStat{VectorOb}, x::AbstractMatrix) = fit!(o, eachrow(x))
fit!(o::OnlineStat{XY}, x::AbstractMatrix) = fit!(o, eachrow(x))
fit!(o::OnlineStat{XY}, xy::Tuple{AbstractMatrix, AbstractVector}) = fit!(o, eachrow(xy...))


#-----------------------------------------------------------------------# text_histogram
# const ticks = ['▁','▂','▃','▄','▅','▆','▇']

# function text_histogram(x)
#     out = ""
#     if !isempty(x)
#         a, b = extrema(x)
#         for xi in x 
#             i = round(Int, 7 * (xi-a) / (b-a))
#             out *= i == 0 ? ' ' : ticks[i]
#         end
#     end
#     out
# end