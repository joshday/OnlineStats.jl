# #-------------------------------------------------------------------------# MV
# struct MV{T, OS <: Tuple} <: OnlineStat{VectorInput}
#     stats::OS
# end
# function MV(args...)
#     T = typeof(args[1])
#     all(x -> typeof(x) == T, args) || throw(ArgumentError("arguments must be same type"))
#     MV{T, typeof(args)}(args)
# end
# MV(p::Integer, o::OnlineStat{ScalarInput}) = MV([copy(o) for i in 1:p]...)
# function Base.show{T}(io::IO, o::MV{T})
#     s = name(o, false) * "{$T}("
#     n = length(o.stats)
#     for i in 1:n
#         s *= "$(value(o.stats[i]))"
#         if i != n
#             s *= ", "
#         end
#     end
#     s *= ")"
#     print(io, s)
# end
# function fit!(o::MV, y::AVec, γ::Float64)
#     stats = o.stats
#     # map((stat, yi) -> fit!(stat, yi, γ), o.stats, y)
#     for i in eachindex(y)
#         fit!(stats[i], y[i], γ)
#     end
#     o
# end


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
    # map((stats, yi) -> fit!(stats, yi, γ), stats, y)
    for (i, yi) in enumerate(y)
        fit!(stats[i], yi, γ)
    end
    o
end
