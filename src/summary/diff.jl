
"""
Track both the last value and the last difference
"""
type Diff{T <: Real} <: OnlineStat
    diff::T
    lastval::T
    n::Int
end

Diff() = Diff(0.0, 0.0, 0)
Diff{T<:Real}(::Type{T}) = Diff(zero(T), zero(T), 0)
Diff{T<:Real}(x::Union(T,AVec{T})) = (o = Diff(T); update!(o, x); o)

statenames(o::Diff) = [:diff, :last, :nobs]
state(o::Diff) = Any[diff(o), last(o), nobs(o)]
Base.last(o::Diff) = o.lastval
Base.diff(o::Diff) = o.diff

function update!{T<:FloatingPoint}(o::Diff{T}, x::Real)
    v = convert(T, x)
    o.diff = (o.n == 0 ? zero(T) : v - last(o))
    o.lastval = v
    o.n += 1
    return
end

function update!{T<:Integer}(o::Diff{T}, x::Real)
    v = round(T, x)
    o.diff = (o.n == 0 ? zero(T) : v - last(o))
    o.lastval = v
    o.n += 1
    return
end

function Base.empty!(o::Diff)
    o.diff = 0.0
    o.lastval = 0.0
    o.n = 0
    return
end

