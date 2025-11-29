"""
    Trace(stat, b=500, f=value)

Wrapper around an OnlineStat that stores `b` "snapshots" (a fixed copy of the OnlineStat).  The snapshots
are taken at approximately equally-spaced intervals between 0 and the current `nobs`.  The main use
case is visualizing state changes as observations are added.

# Example

```julia
using OnlineStats, Plots

o = Trace(Mean(), 10)

fit!(o, 1:100)

OnlineStats.snapshots(o)

plot(o)
```
"""
mutable struct Trace{T, O <: OnlineStat{T}} <: OnlineStat{T}
    parts::Vector{Pair{Tuple{Int,Int}, O}}
    b::Int
    n::Int
end
Trace(o::OnlineStat, b::Int=100) = Trace([(1,1) => o], b, 0)

name(o::Trace, args...) = "Trace($(name(o.parts[end][2], args...)))"
value(o::Trace) = value(o.parts[end][2])

snapshots(o::Trace) = last.(o.parts)

function _fit!(o::Trace, y)
    n = o.n += 1
    parts = o.parts
    (a, b), stat = parts[end]
    a ≤ n ≤ b ?
        _fit!(stat, y) :
        push!(parts, (n, n + ceil(Int, n / o.b) - 1) => fit!(copy(stat), y))
    if length(parts) > o.b && nobs(parts[end][2]) == parts[end][1][2]
        trace_merge_next!(parts)
    end
end

function trace_merge_next!(parts)
    n = parts[1][1][2] - parts[1][1][1]
    i = 1
    for (j, p) in enumerate(parts)
        a, b = p[1]
        b - a < n && (i = j; break;)
    end
    a, b = parts[i], parts[i+1]
    parts[i] = (min(a[1][1], b[1][1]), max(a[1][2], b[1][2])) => b[2]
    deleteat!(parts, i + 1)
end
