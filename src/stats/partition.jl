abstract type AbstractPartition{N} <: OnlineStat{N} end
default_weight(::AbstractPartition) = EqualWeight()

#-----------------------------------------------------------------------# IndexedPart
mutable struct IndexedPart{T, O}
    stat::O
    first::T 
    last::T
    n::Int
end
function IndexedPart(o::OnlineStat, x, y) 
    o2 = copy(o)
    fit!(o2, y, 1.0)
    IndexedPart(o2, x, x, 1)
end
function Base.show(io::IO, o::IndexedPart)
    print(io, name(o) * " (nobs = $(o.n)) : $(o.first) to $(o.last)")
end
function Base.merge!(o::T, o2::T) where {T <: IndexedPart}
    o.n += o2.n
    merge!(o.stat, o2.stat, o2.n / o.n)
    o.last = o2.last
end
value(o::IndexedPart) = value(o.stat)
Base.first(o::IndexedPart) = o.first 
Base.last(o::IndexedPart) = o.last

function fit!(o::IndexedPart{T}, x::T, y) where {T}
    o.n += 1
    fit!(o.stat, y, 1 / o.n)
end
Base.in(x, o::IndexedPart) = (x >= o.first && x <= o.last)
Base.isless(o::IndexedPart, o2::IndexedPart) = o.last < o2.first
nobs(o::IndexedPart) = o.n

function squash!(v::Vector{<:IndexedPart})
    sort!(v)

    diffs = [v[i].last - v[i - 1].first for i in 2:length(v)]

    for k in 1:floor(Int, length(v) / 2)
        _, i = findmin(diffs)
        merge!(v[i], v[i+1])
        deleteat!(v, i + 1)
        deleteat!(diffs, i)
    end
end

#-----------------------------------------------------------------------# IndexedPartition
"""
    IndexedPartition(T, o::OnlineStat{0}, b::Int = 100)

Partition a data stream between `b` and `2b` parts.  The input must have length 2 and is 
assumed to be an (x, y) pair.  The 

# Example

    x = rand(Bool, 100)
    y = x .+ randn(100)

    o = IndexedPartition(Bool, Mean())
    s = Series(Any[x y], o)
    o.parts 
    value(o)
"""
struct IndexedPartition{T, O} <: AbstractPartition{1}
    parts::Vector{IndexedPart{T, O}}
    b::Int
    empty_stat::O
end
function IndexedPartition(T::Type, o::OnlineStat{0}, b::Int = 100)
    v = IndexedPart{T, typeof(o)}[]
    IndexedPartition(v, 2b, copy(o))
end
function Base.show(io::IO, o::IndexedPartition)
    print(io, name(o) * " ($(length(o.parts)) parts)")
end

function fit!(o::IndexedPartition, xy::VectorOb, ::Float64)
    length(xy) == 2 || error("length of input should be 2 (x and y)")
    addpart = true
    x = first(xy)
    parts = o.parts
    for p in parts 
        if x in p 
            fit!(p, xy...)
            addpart = false
        end
    end
    addpart && push!(parts, IndexedPart(o.empty_stat, xy...))
    length(parts) ≥ o.b && squash!(parts)
end

value(o::IndexedPartition) = value.(sort!(o.parts))

#-----------------------------------------------------------------------# Part 
"""
    Part(o::OnlineStat, start::Int)

Summary for a section of data.  `o` is an unfitted OnlineStat to be fitted on observations 
beginning with observation `start`.
"""
mutable struct Part{T <: OnlineStat}
    stat::T     # stat that summarizes the section of data
    start::Int  # first observation
    n::Int      # number of observations in section
end
Part(o::OnlineStat, start::Int) = Part(o, start, 0)
function Base.show(io::IO, o::Part) 
    print(io, "Part: $(o.start) to $(o.start + o.n - 1) ($(o.n) nobs)")
end


# adjacent sections need to be merged (keeping starting observation)
function Base.merge!(o::Part, o2::Part) 
    o.start + o.n == o2.start || error("Cannot merge Parts that are not adjacent.")
    o.n += o2.n
    merge!(o.stat, o2.stat, o2.n / o.n)
end
Base.isless(o::Part, o2::Part) = isless(o.n, o2.n)

fit!(o::Part, y) = (o.n += 1; fit!(o.stat, y, 1 / o.n))
nobs(o::Part) = o.n
stat(o::Part) = o.stat
value(o::Part) = value(o.stat)

function squash!(v::Vector{<:Part})
    lastind = length(v) % 2 == 0 ? length(v) : length(v) - 1
    for i in lastind:-2:2
        merge!(v[i-1], v[i])
        deleteat!(v, i)
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
struct Partition{N, O} <: AbstractPartition{N}
    parts::Vector{Part{O}}
    b::Int
    empty_stat::O
end
function Partition(o::O, b::Int = 100) where {N, O <: OnlineStat{N}}
    Partition{N, O}(Part{O}[], 2b, copy(o))
end
Base.show(io::IO, o::Partition) = print(io, name(o))

nobs(o::Partition) = length(o.parts) == 0 ? 0 : sum(nobs(part) for part in o.parts)

# fit!
function pushpart!(o::Partition, y) 
    p = Part(copy(o.empty_stat), nobs(o) + 1)
    fit!(p, y)
    push!(o.parts, p)
end

function fit!(o::Partition, y, γ::Float64)
    parts = o.parts 
    if length(parts) < 2
        pushpart!(o, y)
    else
        if parts[end].n < parts[end-1].n
            fit!(parts[end], y)
        else 
            pushpart!(o, y)
            length(parts) ≥ o.b && squash!(parts)
        end
    end  
end

# merge 
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

# merge!
function Base.merge!(o::T, o2::T, γ::Float64) where {T<:Partition}
    # adjust o2's start values
    n = nobs(o)
    o2 = copy(o2)
    map(p -> p.start += n, o2.parts)
    # then merge and squash
    append!(o.parts, o2.parts)
    while length(o.parts) ≥ o.b 
        squash_smallest!(o.parts)
    end
    o
end
