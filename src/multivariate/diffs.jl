
"""
Track both the last values and the last differences for more than one series
"""
type Diffs{T <: Real} <: OnlineStat
    diffs::Vector{T}
    lastvals::Vector{T}
    n::Int
end

Diffs(p::Integer) = Diffs(zeros(p), zeros(p), 0)
Diffs{T<:Real}(::Type{T}, p::Integer) = Diffs(zeros(T,p), zeros(T,p), 0)
Diffs{T<:Real}(x::AVec{T}) = (o = Diffs(T,length(x)); update!(o, x); o)
Diffs{T<:Real}(x::AMat{T}) = (o = Diffs(T,ncols(x)); update!(o, x); o)

statenames(o::Diffs) = [:diff, :last, :nobs]
state(o::Diffs) = Any[diff(o), last(o), nobs(o)]
Base.last(o::Diffs) = o.lastvals
Base.diff(o::Diffs) = o.diffs

function update!{T<:Real}(o::Diffs{T}, x::AVec{T})
    o.diffs = (o.n == 0 ? zeros(T,length(o.diffs)) : x - last(o))
    o.lastvals = collect(x)
    o.n += 1
    return
end

function Base.empty!{T<:Real}(o::Diffs{T})
    p = length(o.diffs)
    o.diffs = zeros(T, p)
    o.lastval = zeros(T, p)
    o.n = 0
    return
end

