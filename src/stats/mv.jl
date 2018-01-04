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

function fit!(o::MV, y::VectorOb, γ::Float64)
    stats = o.stats
    for (i, yi) in enumerate(y)
        fit!(stats[i], yi, γ)
    end
    o
end

_value(o::MV) = map(value, o.stats)

Base.merge!(o1::T, o2::T, γ::Float64) where {T <: MV} = merge!.(o1.stats, o2.stats, γ)


#-----------------------------------------------------------------------# Group
struct Group{T} <: ExactStat{1}
    stats::T
end
Group(o::OnlineStat{0}...) = Group(o)
value(o::Group) = value.(o.stats)
Base.show(io::IO, o::Group) = print(io, "Group : $(name.(o.stats, false, false))")
function fit!(o::Group, y::VectorOb, γ::Float64)
    for (oi, yi) in zip(o.stats, y)
        fit!(oi, yi, γ)
    end
end
Base.hcat(o::OnlineStat{0}...) = Group(o)