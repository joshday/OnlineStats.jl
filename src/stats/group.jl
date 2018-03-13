#-----------------------------------------------------------------------# MV
"""
`MV` is deprecated.  Use [`Group`](@ref) instead.

    MV(p, o)
    p * o

Track `p` univariate OnlineStats `o`.

# Example

    y = randn(1000, 5)
    o = MV(5, Mean())
    s = Series(y, o)

    Series(y, 5Mean())
"""
struct MV{T} <: OnlineStat{1}
    stats::Vector{T}
end

default_weight(o::MV) = default_weight(first(o.stats))

function MV(p::Integer, o::OnlineStat{0}) 
    Base.depwarn("MV is deprecated.  Use Group instead.", :MV)
    MV([copy(o) for i in 1:p])
end


for T in [:Mean, :Variance, :Extrema, :Moments]
    @eval MV(p::Integer, o::$T) = MV([$T() for i in 1:p])
end

Base.start(o::MV) = start(o.stats)
Base.next(o::MV, i) = next(o.stats, i)
Base.done(o::MV, i) = done(o.stats, i)

Base.getindex(o::MV, i) = o.stats[i]
Base.first(o::MV) = first(o.stats)
Base.last(o::MV) = last(o.stats)
Base.length(o::MV) = length(o.stats)

# Base.:*(n::Integer, o::OnlineStat{0}) = MV(n, o)

function Base.show(io::IO, o::MV)
    s = name(o) * "("
    n = length(o.stats)
    for i in 1:min(10,n)
        s *= "$(value(o.stats[i]))"
        if i != min(10,n)
            s *= ", "
        end
    end
    if n>10
        s *= ", ..."
    end
    s *= ")"
    print(io, s)
end

function fit!(o::MV, y, γ)
    stats = o.stats
    for (i, yi) in enumerate(y)
        fit!(stats[i], yi, γ)
    end
    o
end

value(o::MV) = map(value, o.stats)

Base.merge!(o1::T, o2::T, γ::Float64) where {T <: MV} = merge!.(o1.stats, o2.stats, γ)


#-----------------------------------------------------------------------# Group
"""
    Group(stats...)
    Group(n::Int, stat)
    [stat1 stat2 stat3 ...]

Create a vector-input stat from several scalar-input stats.  For a new observation `y`, 
`y[i]` is sent to `stats[i]`. 

# Examples

    Series(randn(1000, 3), Group(3, Mean()))

    y = [randn(100) rand(Bool, 100)]
    Series(y, [Mean() CountMap(Bool)])
"""
mutable struct Group{T} <: OnlineStat{1}
    stats::T
    nobs::Int
end
Group(o::OnlineStat{0}...) = Group(o, 0)
Group(n::Int, o::OnlineStat{0}) = Group([copy(o) for i in 1:n], 0)
Group(stats::VectorOb) = Group(stats, 0)

default_weight(o::Group) = default_weight(o.stats)
default_weight(v::Vector) = default_weight(tuple(v...))
value(o::Group) = value.(o.stats)
nobs(o::Group) = o.nobs

Base.show(io::IO, o::Group) = print(io, name(o), ": ", value(o))
Base.length(o::Group) = length(o.stats)
Base.getindex(o::Group, i) = o.stats[i]
Base.first(o::Group) = first(o.stats)
Base.last(o::Group) = last(o.stats)

Base.start(o::Group) = start(o.stats)
Base.next(o::Group, i) = next(o.stats, i)
Base.done(o::Group, i) = done(o.stats, i)

# generated function to unroll loop
@generated function fit!(o::Group{T}, y, γ) where {T<:Tuple}
    N = length(fieldnames(T))
    quote 
        o.nobs += 1
        Base.Cartesian.@nexprs $N i -> @inbounds(fit!(o.stats[i], y[i], γ))
        o
    end
end

function fit!(o::Group{<:Vector}, y, γ) 
    o.nobs += 1
    stats = o.stats
    for (i, yi) in enumerate(y)
        fit!(stats[i], yi, γ)
    end
    o
end

Base.merge!(o::T, o2::T, γ) where {T<:Group} = merge!.(o.stats, o2.stats, γ)

Base.hcat(o::OnlineStat{0}...) = Group(o)

Base.:*(n::Integer, o::OnlineStat{0}) = Group([copy(o) for i in 1:n])

