abstract type AbstractPartition{N} <: OnlineStat{N} end

nobs(o::AbstractPartition) = isempty(o.parts) ? 0 : sum(nobs, o.parts)

#-----------------------------------------------------------------------# Part 
mutable struct Part{T, O <: OnlineStat} <: OnlineStat{VectorOb} 
    stat::O 
    a::T
    b::T 
end
# Part(o::O, ab::T) where {O<:OnlineStat, T} = Part{T,O}(o, ab, ab)
nobs(o::Part) = nobs(o.stat)
Base.show(io::IO, o::Part) = print(io, "Part $(o.a) to $(o.b) | $(o.stat)")
function Base.merge!(o::Part, o2::Part)
    merge!(o.stat, o2.stat)
    o.a = min(o.a, o2.a)
    o.b = max(o.b, o2.b)
    o
end
Base.in(x, o::Part) = (o.a ≤ x ≤ o.b)
Base.isless(o::Part, o2::Part) = o.b < o2.a
value(o::Part) = value(o.stat)
midpoint(o::Part{<:Number}) = (o.a + o.b) / 2
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
    if (length(o.parts) > o.b) && isfull(o.parts[end])
        n = nobs(o.parts[1])
        ind = 1
        for (i, p) in enumerate(o.parts)
            if nobs(p) < n 
                ind = i 
                break
            end
        end
        merge!(o.parts[ind], o.parts[ind+1])
        deleteat!(o.parts, ind+1)
    end
end

#-----------------------------------------------------------------------# IndexedPartition
struct IndexedPartition{IN, O<:OnlineStat{IN}, T} <: AbstractPartition{VectorOb}
    parts::Vector{Part{T, O}}
    b::Int
    init::O
end
function IndexedPartition(T::Type, o::O, b::Int=100) where {IN, O<:OnlineStat{IN}}
    IndexedPartition{IN, O, T}(Part{T, O}[], b, o)
end
function _fit!(o::IndexedPartition, xy)
    x, y = xy
    isempty(o.parts) && push!(o.parts, Part(copy(o.init), x, x))
    addpart = true
    for p in o.parts 
        if x in p 
            addpart = false 
            _fit!(p, xy)
        end
    end
    addpart && push!(o.parts, Part(fit!(copy(o.init), y), x, x))
    if length(o.parts) > o.b 
        sort!(o.parts)
        diff = o.parts[2].a - o.parts[1].b
        ind = 1
        for i in 2:(length(o.parts) - 1)
            newdiff = o.parts[i+1].a - o.parts[i].b
            if newdiff < 0
                @show o.parts[i+1].a
                @show o.parts[i].b 
            end
            if newdiff < diff 
                diff = newdiff 
                ind = i 
            end
        end
        merge!(o.parts[ind], o.parts[ind + 1])
        deleteat!(o.parts, ind + 1)
    end
end