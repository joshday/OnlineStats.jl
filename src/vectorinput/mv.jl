#-------------------------------------------------------------------------# MV
struct MV{T} <: OnlineStat{VectorInput}
    stats::Vector{T}
end
MV(args...) = MV(collect(args))
MV(p::Integer, o::OnlineStat{ScalarInput}) = MV([copy(o) for i in 1:p]...)
function Base.show{T}(io::IO, o::MV{T})
    s = name(o, true) * "("
    n = length(o.stats)
    for i in 1:n
        s *= "$(value(o.stats[i]))"
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
        @inbounds fit!(stats[i], yi, γ)
    end
    o
end
