#-----------------------------------------------------------------------------# KHist
struct KHist2{T, P <: Part{Centroid{T}, Counter{T}}} <: OnlineStat{T}
    parts::Vector{P}
    k::Int
end
function KHist2(k::Int, typ::Type{T} = Float64) where {T<:Number}
    KHist2(Part{Centroid{T}, Counter{T}}[], k)
end
KHist2(k::Int, itr) = fit!(KHist2(k, eltype(itr)), itr)

nobs(o::KHist2) = length(o.parts) < 1 ? 0 : sum(nobs, o.parts)

function Base.push!(o::KHist{T}, p::Part{Centroid{T}, Counter{T}}) where {T}
    parts = o.parts 
    insert!(parts, searchsortedfirst(parts, p), p)
    if length(parts) > o.k 
        mindiff, i = Inf, 0 
        for (j, (a,b)) in enumerate(neighbors(parts))
            diff = Float64(diff(a, b))
            if diff < mindiff 
                mindiff = diff 
                i = j
            end
        end
        parts[i] = merge(parts[i], parts[i+1])
        deleteat!(parts, i+1)
    end
    o
end

_fit!(o::KHist2{T}, y) where {T} = push!(o.parts, Part(fit!(Counter(T), y), Centroid(y)))

# function value(o::KHist) 
#     x, y = xy(o)
#     (centers=x, counts=y)
# end

# function _merge!(a::KHist, b::KHist)
#     for bin in b.bins
#         push!(a, bin)
#     end
# end

# midpoints(o::KHist) = map(center, o.bins)

# # Area of the histogram up to `val` (with linear interpolation)
# function area(o::KHist, val = Inf)
#     x, y = value(o)
#     lastindex = searchsortedlast(x, val)
#     result =  0.0
#     if lastindex > 1
#         result += sum((x[i] - x[i-1]) * (y[i] + y[i-1]) for i in 2:lastindex)
#     end
#     if x[1] < val < x[end]
#         x1, x2 = x[lastindex:(lastindex + 1)]
#         y1, y2 = y[lastindex:(lastindex + 1)]
#         Δ = val - x1
#         interpolated_y = smooth(y1, y2, Δ / (x2 - x1))
#         result += Δ * (interpolated_y + y2)
#     end
#     return 0.5 * result
# end

# # Number of obs that are less than or equal to val (approximate, via linear interpolation)
# function nle(o::KHist{T}, val = Inf) where {T}
#     x, y = value(o)
#     i = searchsortedlast(x, val)
#     yi = i < 1 ? 0.0 : y[i]
#     xi = i < 1 ? zero(T) : x[i]
#     i < 1 ? 0.0 : sum(y[1:i]) + smooth(yi, y[i+1], (val - xi) / (x[i+1] - xi))
# end

# cdf(o::KHist, x) = nle(o, x) / nobs(o)

# function pdf(o::KHist, val)
#     x, y = value(o)
#     i = searchsortedlast(x, val)
#     x1, y1 = x[i], y[i]
#     val == y1 && return y[i] / area(o)
#     x2, y2 = x[i+1], y[i+1]
#     smooth(y1, y2, (val - x1) / (x2 - x1)) / area(o)
# end


# #-----------------------------------------------------------------------------# Base/Statistics
# Base.extrema(o::KHist) = minimum(o), maximum(o)
# Base.minimum(o::KHist) = o.bins[1].domain.center
# Base.maximum(o::KHist) = o.bins[end].domain.center

# function Statistics.mean(o::KHist) 
#     x, y = value(o)
#     mean(x, fweights(y))
# end

# function Statistics.var(o::KHist) 
#     x, y = value(o)
#     var(x, fweights(y); corrected=true)
# end

# function Statistics.quantile(o::KHist, p = [0, .25, .5, .75, 1])
#     x, y = value(o)
#     quantile(x, fweights(y), p)
# end

# Statistics.median(o::KHist) = quantile(o, .5)