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
function Part(o::Part, y::ScalarOb)
    stat = copy(o.stat)
    fit!(stat, y, 1.0)
    Part(stat, o.start + o.n, 1)
end
nobs(o::Part) = o.n
stat(o::Part) = o.stat

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
    value::Vector{Part{T}}
    b::Int  # between b and 2b Parts
    l::Int  # nobs in each Part
    n::Int  # total nobs
    partition_length::Int
end
function Partition(o::T, b::Int = 100) where {T <: OnlineStat{0}} 
    Partition([Part(o, 0, 1)], 2b, 1, 0, 0)
end

function Base.show(io::IO, o::Partition)
    print(io, "Partition of $(o.b): $(name(o.value[1]))")
end


function fit!(o::Partition, y::ScalarOb, γ::Float64)
    o.n += 1

    if o.n == 1 
        o.value[1] = Part(o.value[1], y)
    elseif length(o.value) < o.b 
        if nobs(o.value[end]) < o.l 
            fit!(o.value[end], y)
        else
            push!(o.value, Part(o.value[end], y))
        end
    elseif length(o.value) == o.b 
        if nobs(o.value[end]) < o.l 
            fit!(o.value[end], y)
        else
            squash!(o.value)
            push!(o.value, Part(o.value[end], y))
            o.l *= 2
        end
    else
        error("this shouldn't be possible")
    end
end

# mutable struct Partition{O <: OnlineStat{0}} <: ExactStat{0}
#     summarizer::O 
#     x::Vector{Int}  # partitioned observations
#     y::Vector{O}    # summarizers
#     n::Int
#     k::Int
# end
# function Partition(o::OnlineStat, b::Int = 100)
#     Partition(o, zeros(Int, b), [copy(o) for i in 1:b], 0, 1)
# end
# value(o::Partition) = OrderedDict(zip(o.x, o.y))

# function fit!(o::Partition, y::ScalarOb, γ::Float64)
#     o.n += 1
#     if o.n <= length(o.x)
#         o.x[o.n] = o.n 
#         stat = copy(o.summarizer)
#         fit!(stat, y, γ)
#         o.y[o.n] = stat
#     else
#         o.k += 1
#         stat = o.y[o.k]
#         merge!(o.y[o.k-1], stat)
#     end
# end


    
# mutable struct Summary{O} <: ExactStat{0}
#     summarizer::O

#     summaries::OrderedDict{Int, O}  # starting observation => summary
#     partition::Int
#     n::Int
# end
# function Summary(o::O, partition::Int = 100) where {O}
#     Summary(o, OrderedDict{Int, O}(), partition, 0)
# end 
# value(o::Summary) = o.summaries

# function Base.show(io::IO, o::Summary{O}) where {O}
#     print(io, "Summary of $O")
# end

# function fit!(o::Summary, y::ScalarOb, γ::Float64)
#     o.n += 1
#     newobj = copy(o.summarizer)
#     fit!(newobj, y, γ)
#     o.summaries[o.n] = newobj


#     if o.n % 2o.partition == 0
#         kys = collect(keys(o.summaries))
#         for k in 2:2:2o.partition
#             summary = pop!(o.summaries, kys[k])
#             merge!(o.summaries[kys[k-1]], summary, 1.0)
#         end
#     end
# end