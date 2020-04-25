
#-----------------------------------------------------------------------# Partition 
"""
    Partition(stat, nparts=100; method=:equal)

Split a data stream into `nparts` where each part is summarized by `stat`.  

- `method = :equal`
    - Maintain roughly the same nobs in each part.

# Example 

    o = Partition(Extrema())
    fit!(o, cumsum(randn(10^5)))

    using Plots
    plot(o)
"""
mutable struct Partition{T, O <: OnlineStat{T}, P <: Part{ClosedInterval{Int}, O}} <: OnlineStat{T}
    parts::Vector{P}
    b::Int
    init::O
    method::Symbol
    n::Int
end
function Partition(o::O, b::Int=100; method=:equal) where {O <: OnlineStat}
    Partition(Part{ClosedInterval{Int}, O}[], b, o, method, 0)
end

function _fit!(o::Partition, y)
    isempty(o.parts) && push!(o.parts, Part(copy(o.init), ClosedInterval(1, 1)))
    lastpart = last(o.parts)
    n = o.n += 1
    if n ∈ lastpart 
        _fit!(lastpart, n => y)
    else
        stat = fit!(copy(o.init), y)
        push!(o.parts, Part(stat, ClosedInterval(n, n + nobs(lastpart) - 1)))
    end
    length(o.parts) > o.b && isfull(last(o.parts)) && merge_next!(o.parts, o.method)
end

isfull(p::Part{<:ClosedInterval}) = nobs(p) == p.domain.last - p.domain.first + 1

function merge_next!(parts::Vector{<:Part}, method)
    if method === :equal
        n = nobs(first(parts))
        i = 1
        for (j, p) in enumerate(parts)
            nobs(p) < n && (i = j; break;)
        end
        merge!(parts[i], parts[i + 1])
        deleteat!(parts, i + 1)
    elseif method === :oldest_first
        ind = 1
        error("TODO")
    else
        error("Method is not recognized")
    end
end

# Assumes `a` goes before `b`
function _merge!(a::Partition, b::Partition)
    n = nobs(a)
    a.n += b.n
    for p in b.parts
        push!(a.parts, Part(copy(p.stat), ClosedInterval(p.domain.first + n, p.domain.last + n)))
    end
    while length(a.parts) > a.b
        merge_next!(a.parts, a.method)
    end
    a
end


#-----------------------------------------------------------------------# IndexedPartition
"""
    IndexedPartition(T, stat, b=100)

Summarize data with `stat` over a partition of size `b` where the data is indexed by a 
variable of type `T`.

# Example 

    x, y = randn(10^5), randn(10^6)
    o = IndexedPartition(Float64, Hist(10))
    fit!(o, zip(x, y))

    using Plots 
    plot(o)
"""
mutable struct IndexedPartition{I, T, O <: OnlineStat{T}, P <: Part{ClosedInterval{I}, O}} <: OnlineStat{TwoThings}
    parts::Vector{P}
    b::Int
    init::O
    method::Symbol
    n::Int
end
function IndexedPartition(I::Type, o::O, b::Int=100; method=:weighted_nearest) where {T, O<:OnlineStat{T}}
    IndexedPartition(Part{ClosedInterval{I}, O}[], b, o, method, 0)
end

function _fit!(o::IndexedPartition{I,T,O}, xy) where {I,T,O}
    x, y = xy
    n = o.n += 1
    isempty(o.parts) && push!(o.parts, Part(copy(o.init), ClosedInterval(I(x), I(x))))
    i = findfirst(p -> x in p, o.parts)
    if isnothing(i) 
        push!(o.parts, Part(fit!(copy(o.init), y), ClosedInterval(x, x)))
    else 
        _fit!(o.parts[i], xy)
    end
    length(o.parts) > o.b && indexed_merge_next!(sort!(o.parts), o.method)
end

function indexed_merge_next!(parts::Vector{<:Part}, method)
    if method === :weighted_nearest
        diffs = [diff(a, b) * middle(nobs(a), nobs(b)) for (a, b) in neighbors(parts)]
        _, i = findmin(diffs)
        merge!(parts[i], parts[i + 1])
        deleteat!(parts, i + 1)
    else
        error("method not recognized")
    end
end

function _merge!(o::IndexedPartition, o2::IndexedPartition)
    # If there's any overlap, merge
    for p2 in o2.parts 
        pushpart = true
        for p in o.parts 
            if (p2.domain.first ∈ p) || (p2.domain.last ∈ p)
                pushpart = false
                merge!(p, p2) 
                break               
            end
        end
        pushpart && push!(o.parts, p2)
    end
    # merge parts that overlap 
    for i in reverse(2:length(o.parts))
        p1, p2 = o.parts[i-1], o.parts[i]
        if p1.domain.first > p2.domain.last
            # info("hey I deleted something at $i")
            merge!(p1, p2)
            deleteat!(o.parts, i)
        end
    end
    # merge until there's b left
    sort!(o.parts)
    while length(o.parts) > o.b 
        indexed_merge_next!(o.parts, o.method)
    end
    o
end
