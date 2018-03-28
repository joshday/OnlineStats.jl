#-----------------------------------------------------------------------# General
const Tup = Union{Tuple, NamedTuples.NamedTuple}
const XY = Union{Pair{AbstractVector, Any}, Tuple{AbstractVector, Any}}
const VectorOb = Union{AbstractVector, Tup}

smooth(a, b, γ) = a + γ * (b - a)

function smooth!(a, b, γ)
    for i in eachindex(a)
        a[i] = smooth(a[i], b[i], γ)
    end
end

function smooth_syr!(A::AbstractMatrix, x, γ::Number)
    for j in 1:size(A, 2), i in 1:j
        A[i, j] = smooth(A[i,j], x[i] * x[j], γ)
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

Base.std(o::OnlineStat; kw...) = sqrt.(var(o; kw...))

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

#-----------------------------------------------------------------------# eachrow
struct RowsOf{T, M <: AbstractMatrix{T}}
    mat::M
    buffer::Vector{T}
end
function RowsOf(x::M) where {T, M<:AbstractMatrix{T}}
    RowsOf{T, M}(x, Vector{T}(undef, size(x, 2))) 
end
Base.start(o::RowsOf) = 1
Base.next(o::RowsOf, i) = o[i], i + 1
Base.done(o::RowsOf, i) = i > size(o.mat, 1)
Base.eltype(o::Type{R}) where {T, R<:RowsOf{T}} = Vector{T}
Base.length(o::RowsOf) = size(o.mat, 1)
function Base.getindex(o::RowsOf, i)
    for j in eachindex(o.buffer)
        o.buffer[j] = o.mat[i, j]
    end
    o.buffer
end

#-----------------------------------------------------------------------# xyrows
struct XYRows{T, M <: AbstractMatrix{T}, S, V <: AbstractVector{S}}
    mat::M 
    y::V 
    buffer::Vector{T}
end
function XYRows(x::M, y::V) where {T,S,M<:AbstractMatrix{T},V<:AbstractVector{S}}
    size(x,1) == length(y) || error("incompatible dimensions")
    XYRows{T,M,S,V}(x, y, zeros(T, size(x, 2)))
end
Base.start(o::XYRows) = 1 
Base.next(o::XYRows, i) = o[i], i + 1
Base.done(o::XYRows, i) = i > size(o.mat, 1)
Base.eltype(o::Type{XYRows{T,M,S,V}}) where {T,M,S,V} = Tuple{Vector{T}, S}
Base.length(o::XYRows) = size(o.mat, 1)

function Base.getindex(o::XYRows, i) 
    for j in eachindex(o.buffer)
        o.buffer[j] = o.mat[i, j]
    end
    (o.buffer, o.y[i])
end


#-----------------------------------------------------------------------# eachcol
struct ColsOf{T, M <: AbstractMatrix{T}}
    mat::M 
    buffer::Vector{T}
end
function ColsOf(x::M) where {T, M<:AbstractMatrix{T}}
    ColsOf{T, M}(x, zeros(T, size(x, 1)))
end
Base.start(o::ColsOf) = 1
Base.next(o::ColsOf, i) = o[i], i + 1
Base.done(o::ColsOf, i) = i > size(o.mat, 2)
Base.eltype(o::Type{C}) where {T, C<:ColsOf{T}} = Vector{T}
Base.length(o::ColsOf) = size(o.mat, 2)
function Base.getindex(o::ColsOf, i)
    for j in eachindex(o.buffer)
        o.buffer[j] = o.mat[j, i]
    end
    o.buffer
end

#-----------------------------------------------------------------------# eachrow
"""
    eachrow(x::AbstractMatrix)

Create an iterator over the rows of a matrix as `Vector`s.

    eachrow(x::AbstractMatrix, y::Vector)

Create an iterator over the rows of a matrix/vector as `Tuple{Vector, eltype(y)}`s.
"""
eachrow(x::AbstractMatrix) = RowsOf(x)
eachrow(x::AbstractMatrix, y::AbstractVector) = XYRows(x, y)

"""
    eachcol(x::AbstractMatrix)

Create an iterator over the columns of a matrix as `Vector`s.
"""
eachcol(x::AbstractMatrix) = ColsOf(x)

#-----------------------------------------------------------------------# fit!
# convenience methods
# deprecate?
fit!(o::OnlineStat{VectorOb}, x::AbstractMatrix) = fit!(o, eachrow(x))

fit!(o::OnlineStat{XY}, xy::Tuple{AbstractMatrix, AbstractVector}) = fit!(o, eachrow(xy...))