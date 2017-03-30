#-------------------------------------------------------------------------# MV
struct MV{T} <: OnlineStat{1, -1}
    stats::Vector{T}
end

MV(p::Integer, o::OnlineStat{0}) = MV([copy(o) for i in 1:p])

function Base.show{T}(io::IO, o::MV{T})
    s = name(o, true) * "("
    n = length(o.stats)
    for i in 1:n
        s *= "$(pretty(value(o.stats[i])))"
        if i != n
            s *= ", "
        end
    end
    s *= ")"
    print(io, s)
end

function fit!(o::MV, y::AVec, γ::Float64)
    stats = o.stats
    for (i, yi) in enumerate(y)
        fit!(stats[i], yi, γ)
    end
    o
end

value(o::MV) = map(value, o.stats)
