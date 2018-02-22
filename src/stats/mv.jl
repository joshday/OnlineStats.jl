#-----------------------------------------------------------------------# MV
"""
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

MV(p::Integer, o::OnlineStat{0}) = MV([copy(o) for i in 1:p])

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
Base.:*(n::Integer, o::OnlineStat{0}) = MV(n, o)

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

_value(o::MV) = map(value, o.stats)

Base.merge!(o1::T, o2::T, γ::Float64) where {T <: MV} = merge!.(o1.stats, o2.stats, γ)


#-----------------------------------------------------------------------# Group
"""
    Group(stats...)

Create an `ExactStat{1}` from several `OnlineStat{0}`s.  For a new observation `y`, `y[i]`
is sent to `stats[i]`.  This is designed for working with data of different variable types.

# Example 

    y = [randn(100) rand(["a", "b"], 100)]

    o = Group(Mean(), CountMap(String))

    Series(y, o)
    
    value(o)
"""
struct Group{T} <: ExactStat{1}
    stats::T
end
Group(o::OnlineStat{0}...) = Group(o)
value(o::Group) = value.(o.stats)
Base.show(io::IO, o::Group) = print(io, "Group : $(name.(o.stats, false, false))")
Base.getindex(o::Group, i) = o.stats[i]
function fit!(o::Group, y::VectorOb, γ::Float64)
    for (oi, yi) in zip(o.stats, y)
        fit!(oi, yi, γ)
    end
end
function Base.merge!(o::T, o2::T, γ::Float64) where {T<:Group}
    for (a, b) in zip(o.stats, o2.stats)
        merge!(a, b, γ)
    end
end
Base.hcat(o::OnlineStat{0}...) = Group(o)

