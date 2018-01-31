struct Mosaic{T, S} <: ExactStat{1}
    cm::CountMap{Pair{T,S}}
end
Mosaic(T, S) = Mosaic(CountMap(Pair{T,S}))

function Base.show(io::IO, o::Mosaic{T,S}) where {T, S}
    n1 = length(labels1(o))
    n2 = length(labels2(o))
    print(io, "Mosaic: $T ($n1) × $S ($n2)")
end

Base.keys(o::Mosaic) = keys(o.cm)
labels1(o::Mosaic) = unique(first.(keys(o)))
labels2(o::Mosaic) = unique(last.(keys(o)))

fit!(o::Mosaic, xy::VectorOb, γ::Float64) = fit!(o.cm, Pair(first(xy), last(xy)), γ)

# @recipe function f(o::Mosaic)


#     l1 = labels1(o)
#     n1 = zeros(Int, length(l1))
#     for lab in l1
#         for ky in keys(o)
#             if first(ky) == lab 
#             end
#         end
#     end

#     l2 = labels2(o)
#     l1
# end