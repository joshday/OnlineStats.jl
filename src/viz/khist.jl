"""
    KHist(k::Int)

Estimate the probability density of a univariate distribution at `k` approximately
equally-spaced points.

Ref: <https://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf>

A difference from the above reference is that the minimum and maximum values are not allowed to merge into another bin.

# Example

```julia
o = fit!(KHist(25), randn(10^6))

# Approximate statistics
using Statistics
mean(o)
var(o)
std(o)
quantile(o)
median(o)

using Plots
plot(o)
```
"""
struct KHist{T} <: HistogramStat{T}
    bins::Vector{Pair{T, Int}}  # loc => count
    k::Int
    function KHist(bins::Vector{Pair{T, Int}}, k::Int) where {T}
        k > 2 || error("KHist requires >2 bins")
        new{T}(bins, k)
    end
end
KHist(k::Int, typ::Type{T} = Float64) where {T<:Number} = KHist(Pair{T, Int}[], k)
KHist(k::Int, itr) = fit!(KHist(k, eltype(itr)), itr)

nobs(o::KHist) = length(o.bins) < 1 ? 0 : sum(last, o.bins)

xy(o::KHist) = first.(o.bins), last.(o.bins)
edges(o::KHist) = vcat(first(o.bins[1]), midpoints(first.(o.bins)), first(o.bins[end]))
midpoints(o::KHist) = first.(o.bins)
counts(o::KHist) = last.(o.bins)

function Base.push!(o::KHist{T}, p::Pair{T,Int}) where {T}
    bins = o.bins
    insert!(bins, searchsortedfirst(bins, p), p)
    if length(bins) > o.k
        mindiff = Inf
        i = 0
        for (j, (a,b)) in enumerate(neighbors(bins))
            d = first(b) - first(a)
            if d < mindiff && 1 < j < (length(bins) - 1)  # leave endpoints as extrema
                mindiff = d
                i = j
            end
        end
        a = bins[i]
        b = bins[i + 1]
        n = last(a) + last(b)
        bins[i] = smooth(first(a), first(b), last(b) / n) => n
        deleteat!(bins, i + 1)
    end
    o
end

_fit!(o::KHist{T}, y) where {T} = push!(o, y => 1)

value(o::KHist) = (centers=first.(o.bins), counts=last.(o.bins))

_merge!(a::KHist, b::KHist) = foreach(x -> push!(a, x), b.bins)

#-----------------------------------------------------------------------------# pdf/cdf
ecdf(o::KHist) = ecdf(first.(o.bins); weights=fweights(last.(o.bins)))

# based on linear interpolation
function pdf(o::KHist, x::Number)
    a, b = extrema(o)
    if x < a || x > b
        return 0.0
    elseif x == a
        return last(o.bins[1]) / area(o)
    else
        i = searchsortedfirst(o.bins, x => 0)
        x1, y1 = o.bins[i-1]
        x2, y2 = o.bins[i]
        return smooth(y1, y2, (x-x1) / (x2 - x1)) / area(o)
    end
end

area(o::KHist) = area(value(o)...)
area(x, y) = 0.5 * sum((x[i] - x[i-1]) * (y[i] + y[i-1]) for i in 2:length(x))

#-----------------------------------------------------------------------------# statistics
Base.extrema(o::KHist) = first(o.bins[1]), first(o.bins[end])
function Statistics.mean(o::KHist)
    x, y = xy(o)
    mean(x, fweights(y))
end
function Statistics.var(o::KHist)
    x, y = xy(o)
    var(x, fweights(y); corrected=true)
end
function Statistics.quantile(o::KHist, q=[0, .25, .5, .75, 1])
    x, y = xy(o)
    quantile(x, fweights(y), q)
end
Statistics.median(o::KHist) = quantile(o, .5)

#-----------------------------------------------------------------------------# plot
@recipe function f(o::KHist; normalize=true)
    seriestype --> :sticks
    x, y = xy(o)
    y2 = normalize ? y ./ area(o) : y
    fillrange --> 0
    seriesalpha --> .5
    x, y2
end
