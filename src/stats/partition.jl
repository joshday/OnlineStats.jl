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
# Base.isless(o::Part, o2::Part) = isless(o.n, o2.n)

fit!(o::Part, y::ScalarOb) = (o.n += 1; fit!(o.stat, y, 1 / o.n))
nobs(o::Part) = o.n
stat(o::Part) = o.stat
value(o::Part) = value(o.stat)

function squash!(v::Vector{<:Part})
    length(v) % 2 == 0 || error("Squashing an odd number of Parts is not defined.")
    for i in length(v):-2:2
        merge!(v[i-1], v[i])
        deleteat!(v, i)
    end
end

#-----------------------------------------------------------------------# Partition
"""
    Partition(o::OnlineStat, b = 50)

Split a data stream between `b` and `2b` parts, using `o` to summarize each part.

# Example

    y = randn(1000)
    o = Partition(Mean())
    Series(y, o)
    m = merge(o)  # merge partitions into a single `Mean`
    value(m) ≈ mean(y)

    using Plots
    plot(o)
"""
struct Partition{T} <: ExactStat{0}
    parts::Vector{Part{T}}
    b::Int  # between b and 2b Parts
    empty_stat::T
end
function Partition(o::T, b::Int = 50) where {T <: OnlineStat{0}}
    Partition(Part{T}[], 2b, copy(o))
end
Base.show(io::IO, o::Partition) = print(io, name(o))

nobs(o::Partition) = length(o.parts) == 0 ? 0 : sum(nobs(part) for part in o.parts)

# fit!
function pushpart!(o::Partition, y::ScalarOb) 
    p = Part(copy(o.empty_stat), nobs(o) + 1)
    fit!(p, y)
    push!(o.parts, p)
end

function fit!(o::Partition, y::ScalarOb, γ::Float64)
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
    # make sure o2's parts have same nobs
    while nobs(o.parts[1]) > nobs(o2.parts[1])
        squash!(o2.parts)
    end
    # then merge 
    append!(o.parts, o2.parts)
    while length(o.parts) > o.b 
        squash!(o.parts)
    end
    o
end