\#-----------------------------------------------------------------------# Partition
"""
    Partition(stat)
    Partition(stat, nparts)

Split a data stream into `nparts` (default 100) where each part is summarized by `stat`.

# Example

```julia
o = Partition(Extrema())
fit!(o, cumsum(randn(10^5)))

using Plots
plot(o)
```
"""
mutable struct Partition{T, I, O <: OnlineStat{T}} <: OnlineStat{T}
    parts::Vector{Pair{Tuple{Int,Int}, O}} # (a,b) => stat
    b::Int
    init::I
    n::Int
end
Partition(init::Function, b::Int=100) = Partition([(1,1) => init()], b, init, 0)
Partition(o::OnlineStat, b::Int=100) = Partition(() -> copy(o), b)

OnlineStatsBase.additional_info(o::Partition) = (;b = o.b)
value(o::Partition) = (o.parts[1][1][1], o.parts[end][1][2]) => value(reduce(merge!, last.(o.parts), init=o.init()))

function _fit!(o::Partition, y)
    n = (o.n += 1)
    parts = o.parts
    lastpart = parts[end]
    (a, b), stat = lastpart
    if a ≤ n ≤ b
        _fit!(stat, y)
    else
        lastpart = (n, n + nobs(stat) - 1) => fit!(o.init(), y)
        push!(parts, lastpart)
    end
    length(parts) > o.b && nobs(lastpart[2]) == (b - a + 1) && merge_next!(parts)
end

function merge_next!(parts)
    n = nobs(parts[1][2])
    i = 1
    for (j, p) in enumerate(parts)
        nobs(p[2]) < n && (i = j; break;)
    end
    # a, b = parts[i], parts[i+1]
    ((a1, b1), stat1), ((a2,b2), stat2) = parts[i], parts[i+1]
    parts[i] = (min(a1, a2), max(b1, b2)) => merge!(stat1, stat2)
    deleteat!(parts, i + 1)
end

# Assumes `a` goes before `b`
function _merge!(a::Partition, b::Partition)
    n = nobs(a)
    a.n += b.n
    for p in b.parts
        push!(a.parts, (p[1][1] + n, p[1][2] + n) => copy(p[2]))
    end
    while length(a.parts) > a.b
        merge_next!(a.parts)
    end
    a
end


#-----------------------------------------------------------------------# IndexedPartition
"""
    IndexedPartition(T, stat, b=100)

Summarize data with `stat` over a partition of size `b` where the data is indexed by a
variable of type `T`.

# Example

```julia
x, y = randn(10^5), randn(10^6)
o = IndexedPartition(Float64, KHist(10))
fit!(o, zip(x, y))

using Plots
plot(o)
```
"""
mutable struct IndexedPartition{I, T, O <: OnlineStat{T}, P <: Pair{<:Tuple, O}} <: OnlineStat{TwoThings{I,T}}
    parts::Vector{P}
    b::Int
    init::O
    n::Int
end
function IndexedPartition(I::Type, o::O, b::Int=100) where {T, O<:OnlineStat{T}}
    IndexedPartition{I,T, O,Pair{Tuple{I,I}, O}}(Pair{Tuple{I,I}, O}[], b, o, 0)
end
value(o::IndexedPartition) = nobs(o) == 0 ?
    nothing => value(copy(o.init)) :
    (o.parts[1][1][1], o.parts[end][1][2]) => value(reduce(merge!, last.(o.parts), init=copy(o.init)))

function _fit!(o::IndexedPartition{I}, xy) where {I}
    x, y = xy
    n = o.n += 1
    isempty(o.parts) && push!(o.parts, (I(x), I(x)) => copy(o.init))
    i = findfirst(p -> p[1][1] ≤ x ≤ p[1][2], o.parts)
    if isnothing(i)
        push!(o.parts, (I(x), I(x)) => fit!(copy(o.init), y))
    else
        _fit!(o.parts[i][2], y)
    end
    length(o.parts) > o.b && indexed_merge_next!(sort!(o.parts, by = x -> x[1][1]))
end

function indexed_merge_next!(parts)
    diffs = map(neighbors(parts)) do (a, b)
        (b[1][1] - a[1][2]) * round(Int, middle(nobs(a[2]), nobs(b[2])))
    end
    _, i = findmin(diffs)
    parts[i] = (parts[i][1][1], parts[i+1][1][2]) => merge!(parts[i][2], parts[i + 1][2])
    deleteat!(parts, i + 1)
end

function _merge!(p1::IndexedPartition, p2::IndexedPartition)
    sort!(append!(p1.parts, p2.parts), by = x -> x[1][1])
    p1.n += p2.n
    while length(p1.parts) > p1.b
        indexed_merge_next!(p1.parts)
    end
end

#-----------------------------------------------------------------------------# KIndexedPartition
"""
    KIndexedPartition(T, stat_init, k=100)

Similar to [`IndexedPartition`](@ref), but indexes the first variable by centroids (like [`KHist`](@ref))
rather than intervals.

- Note: `stat_init` must be a function e.g. `() -> Mean()`

# Example

```julia
using Plots

o = KIndexedPartition(Float64, () -> KHist(10))

fit!(o, zip(randn(10^6), randn(10^6)))

plot(o)
```
"""
mutable struct KIndexedPartition{I,T,O<:OnlineStat{T},F} <: OnlineStat{TwoThings{I,T}}
    parts::Vector{Pair{I,O}}
    k::Int
    init::F
    n::Int
end
function KIndexedPartition(I::Type, init::Base.Callable, k::Int=100)
    o = init()
    T, O = OnlineStatsBase.input(o), typeof(o)
    KIndexedPartition{I,T,O,typeof(init)}(Pair{I,O}[], k, init, 0)
end
value(o::KIndexedPartition) =
    (o.parts[1][1][1], o.parts[end][1][2]) => value(reduce(merge!, last.(o.parts), init=o.init()))


function _fit!(o::KIndexedPartition, xy)
    x, y = xy
    parts = o.parts
    newpart = x => fit!(o.init(), y)
    insert!(parts, searchsortedfirst(parts, newpart; by=first), newpart)
    length(parts) > o.k && kindexed_merge_next!(parts)
end

function kindexed_merge_next!(parts)
    mindiff = Inf
    i = 0
    for (j, (a,b)) in enumerate(neighbors(parts))
        d = first(b) - first(a)
        if d < mindiff && 1 < j < (length(parts) - 1)
            mindiff = d
            i = j
        end
    end
    a = parts[i]
    b = parts[i + 1]
    n = nobs(last(a)) + nobs(last(b))
    parts[i] = smooth(first(a), first(b), nobs(last(b)) / n) => merge!(a[2], b[2])
    deleteat!(parts, i + 1)
end

function _merge!(a::KIndexedPartition, b::KIndexedPartition)
    sort!(append!(a.parts, b.parts), by=first)
    while length(a.parts) > a.k
        kindexed_merge_next!(a.parts)
    end
end
