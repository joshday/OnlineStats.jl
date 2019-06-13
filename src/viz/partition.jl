abstract type AbstractPartition{N} <: OnlineStat{N} end

nobs(o::AbstractPartition) = isempty(o.parts) ? 0 : sum(nobs, o.parts)

#-----------------------------------------------------------------------# Part 
"""
    Part(stat, a, b)

`stat` summarizes a Y variable over an X variable's range `a` to `b`.
"""
mutable struct Part{T, O <: OnlineStat} <: OnlineStat{VectorOb} 
    stat::O 
    a::T
    b::T 
end
# Part(o::O, ab::T) where {O<:OnlineStat, T} = Part{T,O}(o, ab, ab)
nobs(o::Part) = nobs(o.stat)
Base.show(io::IO, o::Part) = print(io, "Part $(o.a) to $(o.b) | $(o.stat)")
function _merge!(o::Part, o2::Part)
    _merge!(o.stat, o2.stat)
    o.a = min(o.a, o2.a)
    o.b = max(o.b, o2.b)
    o
end
Base.in(x, o::Part) = (o.a ≤ x ≤ o.b)
Base.isless(o::Part, o2::Part) = o.b < o2.a
value(o::Part) = value(o.stat)

midpoint(o::Part{<:Number}) = middle(o.a, o.b)

function midpoint(o::Part) 
    if o.a == o.b 
        return o.a 
    else
        return (o.a:o.b)[round(Int, length(o.a:o.b) / 2)]
    end
end

midpoint(o::Part{<:TimeType}) = o.a + fld(o.b - o.a, 2)

width(o::Part) = o.b - o.a

isfull(o::Part{Int}) = (nobs(o) == o.b - o.a + 1)

function _fit!(p::Part, xy)
    x, y = xy
    x in p || error("$x ∉ [$(o.a), $(o.b)]")
    _fit!(p.stat, y)
end

#-----------------------------------------------------------------------# Partition 
"""
    Partition(stat, nparts=100)

Split a data stream into `nparts` where each part is summarized by `stat`.

# Example 

    o = Partition(Extrema())
    fit!(o, cumsum(randn(10^5)))

    using Plots
    plot(o)
"""
struct Partition{T, O <: OnlineStat{T}} <: AbstractPartition{T}
    parts::Vector{Part{Int, O}}
    b::Int  # max partition size 
    init::O
end
function Partition(o::O, b::Int=100) where {T, O<:OnlineStat{T}}
    Partition{T, O}(Part{Int, O}[], b, o)
end
function _fit!(o::Partition, y)
    isempty(o.parts) && push!(o.parts, Part(copy(o.init), 1, 1))
    lastpart = last(o.parts)
    n = nobs(o)
    if (n + 1) ∈ lastpart 
        _fit!(lastpart, (n+1, y))
    else
        stat = fit!(copy(o.init), y)
        push!(o.parts, Part(stat, n + 1, n + nobs(lastpart)))
    end
    (length(o.parts) > o.b) && isfull(o.parts[end]) && merge_next!(o.parts)
end
function _merge!(o::Partition, o2::Partition)
    n = nobs(o)
    for p in o2.parts
        push!(o.parts, Part(copy(p.stat), p.a + n, p.b + n))
    end
    while length(o.parts) > o.b
        merge_next!(o.parts)
    end
    o
end
function merge_next!(parts::Vector{<:Part})
    n = nobs(parts[1])
    ind = 1
    for (i, p) in enumerate(parts)
        if nobs(p) < n 
            ind = i 
            break
        end
    end
    if ind == length(parts)
        ind -= 1
    end
    merge!(parts[ind], parts[ind+1])
    deleteat!(parts, ind + 1)
end

#-----------------------------------------------------------------------# IndexedPartition
"""
    IndexedPartition(T, stat, b=100)

Summarize data with `stat` over a partition of size `b` where the data is indexed by a 
variable of type `T`.

# Example 

    o = IndexedPartition(Float64, Hist(10))
    fit!(o, randn(10^4, 2))

    using Plots 
    plot(o)
"""
struct IndexedPartition{IN, O<:OnlineStat{IN}, T} <: AbstractPartition{VectorOb}
    parts::Vector{Part{T, O}}
    b::Int
    init::O
end
function IndexedPartition(T::Type, o::O, b::Int=100) where {IN, O<:OnlineStat{IN}}
    IndexedPartition{IN, O, T}(Part{T, O}[], b, o)
end
function _fit!(o::IndexedPartition{I,O,T}, xy) where {I,O,T}
    x, y = xy
    isempty(o.parts) && push!(o.parts, Part(copy(o.init), T(x), T(x)))
    addpart = true
    for p in o.parts 
        if x in p 
            addpart = false 
            _fit!(p, xy)
            break
        end
    end
    addpart && push!(o.parts, Part(fit!(copy(o.init), y), x, x))
    length(o.parts) > o.b && merge_nearest!(sort!(o.parts))
end

function merge_nearest!(parts::Vector{<:Part})
    diff = get_diff(parts[1], parts[2])
    ind = 1
    for i in 2:(length(parts) - 1)
        newdiff = get_diff(parts[i], parts[i+1])
        if newdiff < diff 
            diff = newdiff 
            ind = i 
        end
    end
    merge!(parts[ind], parts[ind + 1])
    deleteat!(parts, ind + 1)
end


get_diff(a::Part{T}, b::Part{T}) where {T<:Dates.TimeType} = 
    (Dates.value(b.a) - Dates.value(a.b)) * (nobs(a) + nobs(b)) / 2

get_diff(a::Part{T}, b::Part{T}) where {T<:Number} = (b.a - a.b) * (nobs(a) + nobs(b)) / 2

function _merge!(o::IndexedPartition, o2::IndexedPartition)
    # If there's any overlap, merge
    for p2 in o2.parts 
        pushpart = true
        for p in o.parts 
            if (p2.a ∈ p) || (p2.b ∈ p)
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
        if p1.a > p2.b
            # info("hey I deleted something at $i")
            merge!(p1, p2)
            deleteat!(o.parts, i)
        end
    end
    # merge until there's b left
    sort!(o.parts)
    while length(o.parts) > o.b 
        merge_nearest!(o.parts)
    end
    o
end
