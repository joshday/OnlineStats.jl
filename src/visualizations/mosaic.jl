# struct Mosaic{T, S} <: ExactStat{1}
#     cm::CountMap{Pair{T,S}}
# end
# Mosaic(T, S) = Mosaic(CountMap(Pair{T,S}))

# function Base.show(io::IO, o::Mosaic{T,S}) where {T, S}
#     n1 = length(labels1(o))
#     n2 = length(labels2(o))
#     print(io, "Mosaic: $T ($n1) × $S ($n2)")
# end

# Base.keys(o::Mosaic) = keys(o.cm)
# Base.values(o::Mosaic) = values(o.cm)
# probs(o::Mosaic) = probs(o.cm)

# labels1(o::Mosaic) = unique(first.(keys(o)))
# labels2(o::Mosaic) = unique(last.(keys(o)))

# fit!(o::Mosaic, xy::VectorOb, γ::Float64) = fit!(o.cm, Pair(first(xy), last(xy)), γ)

# @recipe function f(o::Mosaic{T,S}) where {T,S}
#     kys, prbs = keys(o), probs(o)
#     l1, l2 = first.(kys), last.(kys)
#     l1widths =
# end