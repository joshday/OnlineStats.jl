#-----------------------------------------------------------------------# General
const Tup = Union{Tuple, NamedTuples.NamedTuple}
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
    RowsOf{T, M}(x, zeros(T, size(x, 2)))
end
eachrow(x::AbstractMatrix) = RowsOf(x)
Base.start(o::RowsOf) = 1
function Base.next(o::RowsOf, i) 
    for j in eachindex(o.buffer)
        o.buffer[j] = o.mat[i, j]
    end
    o.buffer, i + 1
end
Base.done(o::RowsOf, i) = i > size(o.mat, 1)
Base.eltype(o::Type{RowsOf{T}}) where {T} = Vector{T}
Base.length(o::RowsOf) = size(o.mat, 1)


#-----------------------------------------------------------------------# eachcol
struct ColsOf{T, M <: AbstractMatrix{T}}
    mat::M 
    buffer::Vector{T}
end
function ColsOf(x::M) where {T, M<:AbstractMatrix{T}}
    ColsOf{T, M}(x, zeros(T, size(x, 1)))
end
eachcol(x::AbstractMatrix) = ColsOf(x)
Base.start(o::ColsOf) = 1
function Base.next(o::ColsOf, i) 
    for j in eachindex(o.buffer)
        o.buffer[j] = o.mat[j, i]
    end
    o.buffer, i + 1
end
Base.done(o::ColsOf, i) = i > size(o.mat, 2)
Base.eltype(o::Type{ColsOf{T}}) where {T} = Vector{T}
Base.length(o::ColsOf) = size(o.mat, 2)

#-----------------------------------------------------------------------# fit!
fit!(o::OnlineStat{T}, y::T) where {T} = (_fit!(o, y); o)

function fit!(o::OnlineStat{T}, y::AbstractArray{<:T}) where {T}
    for yi in y 
        _fit!(o, yi)
    end
    o
end

function fit!(o::OnlineStat{VectorOb}, y::AbstractMatrix)
    for yi in eachrow(y)
        _fit!(o, yi)
    end
    o
end

function fit!(o::OnlineStat{VectorOb}, y::Tup)
    x, y = y 
    n, p = size(x)
    buffer = Vector{eltype(x)}(undef, p)
    for i in 1:n 
        for j in 1:p 
            @inbounds buffer[j] = x[i, j]
        end
        _fit!(o, (buffer, y[i]))
    end
    o
end