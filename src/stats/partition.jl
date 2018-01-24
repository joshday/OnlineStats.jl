abstract type AbstractPartition{N} <: OnlineStat{N} end
default_weight(::AbstractPartition) = EqualWeight()
nobs(o::AbstractPartition) = length(o.parts) == 0 ? 0 : sum(nobs(part) for part in o.parts)
function Base.show(io::IO, o::AbstractPartition)
    print(io, name(o) * " ($(length(o.parts)) parts)")
end

#-----------------------------------------------------------------------# Part
# Section of a bivarate relationship
mutable struct Part{T, O <: OnlineStat}
    stat::O
    first::T 
    last::T 
    n::Int
end
Part(o::OnlineStat, x, y) = (o2 = copy(o); fit!(o2, y, 1.0); Part(o2, x, x, 1))
function Base.show(io::IO, o::Part)
    print(io, name(o), ": $(o.n) nobs in $(o.first) to $(o.last)")
end
function Base.merge!(p::Part, p2::Part)
    p.n += p2.n 
    merge!(p.stat, p2.stat, p2.n / p.n)
    p.first = min(p.first, p2.first)
    p.last = max(p.last, p2.last)
    p
end
Base.in(x, o::Part) = (x >= o.first && x <= o.last)
Base.first(o::Part) = o.first 
Base.last(o::Part) = o.last
Base.isless(o::Part, o2::Part) = last(o) < first(o2)
nobs(o::Part) = o.n
value(o::Part) = value(o.stat)

function fit!(p::Part{T}, x::T, data) where {T}
    x in p || error("$x is not between $(p.first) and $(p.last)")
    p.n += 1
    fit!(p.stat, data, 1 / p.n)
end
function Base.push!(p::Part{T}, x::T, data) where {T}
    p.n += 1
    p.last = max(p.last, x)
    fit!(p.stat, data, 1 / p.n)
end

#-----------------------------------------------------------------------# squashing logic
function squash_every_other!(v::Vector{<:Part})
    lastind = length(v) % 2 == 0 ? length(v) : length(v) - 1
    for i in lastind:-2:2
        merge!(v[i-1], v[i])
        deleteat!(v, i)
    end
end

function squash_nearest!(v::Vector{<:Part}, b::Integer)
    sort!(v)
    diffs = [first(v[i]) - last(v[i - 1]) for i in 2:length(v)]
    while length(v) ≥ b
        # if equally-spaced, randomly pick bins to merge
        i = rand(find(x -> x == minimum(diffs), diffs))
        merge!(v[i], v[i+1])
        deleteat!(v, i + 1)
        deleteat!(diffs, i)
    end 
end

function squash_smallest!(v::Vector{<:Part})
    _, i = findmin(nobs(part) for part in v)
    n_left = (i == 1) ? typemax(Int) : nobs(v[i - 1])
    n_right = (i == length(v)) ? typemax(Int) : nobs(v[i + 1])
    ind = (n_left < n_right) ? i - 1 : i + 1
    merge!(v[i], v[ind])
    deleteat!(v, ind)
end

#-----------------------------------------------------------------------# Partition 
"""
    Partition(o::OnlineStat, b::Int)

Incrementally partition a data stream where between `b` and `2b` sections are summarized 
by `o`. 

# Example 

    using Plots
    s = Series(cumsum(randn(10^6)), Partition(Mean()))
    plot(s)
"""
struct Partition{N, O <: OnlineStat{N}} <: AbstractPartition{N}
    parts::Vector{Part{Int, O}}
    b::Int  # max partition size 
    empty_stat::O
end
function Partition(o::OnlineStat{N}, b::Integer = 100) where {N}
    O = typeof(o)
    Partition{N, O}(Part{Int, O}[], 2b, copy(o))
end

value(o::Partition) = value.(o.parts)

function fit!(o::Partition, y, γ::Float64)
    parts = o.parts 
    if length(parts) < 2
        push!(parts, Part(o.empty_stat, nobs(o) + 1, y))
    else
        lastpart = last(parts)
        if nobs(lastpart) < nobs(parts[end-1])
            push!(lastpart, lastpart.last + 1, y)
        else
            push!(parts, Part(o.empty_stat, nobs(o) + 1, y))
            length(parts) ≥ o.b && squash_every_other!(parts)
        end
    end
end
function Base.merge(o::Partition)
    n = first(o.parts).n
    stat = first(o.parts).stat
    for i in 2:length(o.parts)
        n2 = o.parts[i].n 
        n += n2 
        merge!(stat, o.parts[i].stat, n2 / n)
    end
    stat
end

function Base.merge!(o::T, o2::T, γ::Float64) where {T<:Partition}
    # adjust o2's start values
    n = nobs(o)
    o2 = copy(o2)
    map(p -> p.first += n, o2.parts)
    # then merge and squash
    append!(o.parts, o2.parts)
    while length(o.parts) ≥ o.b 
        squash_smallest!(o.parts)
    end
    o
end

#-----------------------------------------------------------------------# IndexedPartition 
struct IndexedPartition{T, O <: OnlineStat} <: AbstractPartition{1}
    parts::Vector{Part{T, O}}
    b::Int  # max partition size 
    empty_stat::O
end
function IndexedPartition(T::Type, o::OnlineStat, b::Int = 100)
    IndexedPartition(Part{T, typeof(o)}[], 2b, copy(o))
end

function fit!(o::IndexedPartition, xy::VectorOb, ::Float64)
    length(xy) == 2 || error("length of input should be 2 (x and y)")
    addpart = true
    x = first(xy)
    parts = o.parts
    for p in parts 
        if x in p 
            fit!(p, x, last(xy))
            addpart = false
        end
    end
    addpart && push!(parts, Part(o.empty_stat, xy...))
    length(parts) ≥ o.b && squash_nearest!(parts, floor(Int, o.b/2))
end

value(o::IndexedPartition) = value.(sort!(o.parts))

function Base.merge(o::IndexedPartition)
    n = first(o.parts).n
    stat = first(o.parts).stat
    for i in 2:length(o.parts)
        n2 = o.parts[i].n 
        n += n2 
        merge!(stat, o.parts[i].stat, n2 / n)
    end
    stat
end

function Base.merge!(o::T, o2::T, γ::Float64) where {T<:IndexedPartition}
    append!(o.parts, o2.parts)
    squash_nearest!(o.parts, o.b)
    o
end