#-------------------------------------------------------------------------# MV
"""
    MV(p, o)
Track `p` univariate OnlineStats `o`
### Example
```julia
y = randn(1000, 5)
o = MV(5, Mean())
s = Series(y, o)
```
"""
struct MV{T} <: OnlineStat{1, -1, nothing}
    stats::Vector{T}
end
weight(o::MV) = weight(o.stats[1])

MV(p::Integer, o::OnlineStat{0}) = MV([copy(o) for i in 1:p])

for T in [:Mean, :Variance, :Extrema, :Moments, :OrderStats]
    @eval MV(p::Integer, o::$T) = MV([$T() for i in 1:p])
end

function Base.show{T}(io::IO, o::MV{T})
    s = OnlineStatsBase.name(o, true) * "("
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

value(o::MV) = map(value, o.stats)

Base.merge!{T <: MV}(o1::T, o2::T, γ::Float64) = merge!.(o1.stats, o2.stats, γ)
