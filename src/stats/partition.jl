#-----------------------------------------------------------------------# Part 
"""
    # create first part
    Part(o::OnlineStat, start::Int, n::Int)

    # create next part
    Part(p::Part, y::ScalarOb)  # create

Summary for a section of data.  `stat` is the OnlineStat evaluated on `n` observations 
beginning with `start`.
"""
mutable struct Part{T <: OnlineStat}
    stat::T     # stat that summarizes the section of data
    start::Int  # first observation
    n::Int      # number of observations in section
end
function Base.show(io::IO, o::Part) 
    print(io, "Part(start = $(o.start), nobs = $(o.n))")
end

# adjacent sections need to be merged (maintaining starting observation)
function Base.merge!(o::Part, o2::Part) 
    o.start + o.n == o2.start || error("don't merge Parts that aren't adjacent!")
    o.n += o2.n
    merge!(o.stat, o2.stat, o2.n / o.n)
end
Base.isless(o::Part, o2::Part) = isless(o.n, o2.n)

fit!(o::Part, y::ScalarOb) = (o.n += 1; fit!(o.stat, y, 1 / o.n))
function Part(p::Part, o::OnlineStat, y::ScalarOb)
    stat = copy(o)
    fit!(stat, y, 1.0)
    Part(stat, p.start + p.n, 1)
end
nobs(o::Part) = o.n
stat(o::Part) = o.stat

value(o::Part) = value(o.stat)

function squash!(v::Vector{<:Part})
    length(v) % 2 == 0 || error("you shouldn't be squashing yet...")
    for i in length(v):-2:2
        merge!(v[i-1], v[i])
        deleteat!(v, i)
    end
end

#-----------------------------------------------------------------------# partition
"""
    Partition(o::OnlineStat, b = 100)

Split a data stream between `b` and `2 * b` parts, using `o` to summarize each part.
"""
mutable struct Partition{T} <: ExactStat{0}
    parts::Vector{Part{T}}
    b::Int  # between b and 2b Parts
    l::Int  # nobs in each Part
    n::Int  # total nobs
    summarizer::T  # empty stat to make copies of
end
function Partition(o::T, b::Int = 100) where {T <: OnlineStat{0}} 
    Partition([Part(o, 0, 1)], 2b, 1, 0, o)
end

function Base.show(io::IO, o::Partition)
    print(io, "Partition of $(o.b): $(name(o.parts[1]))")
end

function Base.merge!(o::Partition, o2::Partition, γ::Float64)
    # TODO
    error("this is kinda hard...but possible")
end


function fit!(o::Partition, y::ScalarOb, γ::Float64)
    o.n += 1
    parts = o.parts
    if o.n == 1 
        parts[1] = Part(parts[1], o.summarizer, y)
    elseif length(parts) < o.b 
        if nobs(parts[end]) < o.l 
            fit!(parts[end], y)
        else
            push!(parts, Part(parts[end], o.summarizer, y))
        end
    elseif length(parts) == o.b 
        if nobs(parts[end]) < o.l 
            fit!(parts[end], y)
        else
            squash!(parts)
            push!(parts, Part(parts[end], o.summarizer, y))
            o.l *= 2
        end
    else
        error("this shouldn't be possible")
    end
end