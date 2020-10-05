#-----------------------------------------------------------------------# common
abstract type HistogramStat{T} <: OnlineStat{T} end

# Index of `edges` that `y` belongs in, depending on if bins are `left` closed and if
# the bin on the end is `closed` instead of half-open.
function binindex(edges::AbstractVector, y, left::Bool, closed::Bool)
    a, b = extrema(edges)
    y < a && return 0
    y > b && return length(edges)
    closed && y == a && return 1
    closed && y == b && return length(edges) - 1
    if left
        if isa(edges, AbstractRange)
            return floor(Int, (y - a) / step(edges)) + 1
        else
            return searchsortedlast(edges, y)
        end
    else
        if isa(edges, AbstractRange)
            return ceil(Int, (y - a) / step(edges))
        else
            return searchsortedfirst(edges, y) - 1
        end
    end
end

# requires: edges(o), midpoints(o), counts(o)
split_candidates(o::HistogramStat) = midpoints(o)
Statistics.mean(o::HistogramStat) = mean(midpoints(o), fweights(counts(o)))
Statistics.var(o::HistogramStat) = var(midpoints(o), fweights(counts(o)); corrected=true)
Statistics.std(o::HistogramStat) = sqrt(var(o))
Statistics.median(o::HistogramStat) = quantile(o, .5)
function Base.extrema(o::HistogramStat)
    x, y = midpoints(o), counts(o)
    x[findfirst(x -> x > 0, y)], x[findlast(x -> x > 0, y)]
end
function Statistics.quantile(o::HistogramStat, p = [0, .25, .5, .75, 1])
    x, y = midpoints(o), counts(o)
    inds = findall(x -> x != 0, y)
    quantile(x[inds], fweights(y[inds]), p)
end



#-----------------------------------------------------------------------# Hist
"""
    Hist(edges; left = true, closed = true)

Create a histogram with bin partition defined by `edges`.

- If `left`, the bins will be left-closed.
- If `closed`, the bin on the end will be closed.
    - E.g. for a two bin histogram ``[a, b), [b, c)`` vs. ``[a, b), [b, c]``

# Example

    o = fit!(Hist(-5:.1:5), randn(10^6))

    # approximate statistics
    using Statistics

    mean(o)
    var(o)
    std(o)
    quantile(o)
    median(o)
    extrema(o)
"""
struct Hist{T, R} <: HistogramStat{T}
    edges::R
    counts::Vector{Int}
    out::Vector{Int}
    left::Bool
    closed::Bool

    function Hist(edges::R, T::Type = eltype(edges); left::Bool=true, closed::Bool=true) where {R<:AbstractVector}
        new{T,R}(edges, zeros(Int, length(edges) - 1), [0,0], left, closed)
    end
end
nobs(o::Hist) = sum(o.counts) + sum(o.out)
value(o::Hist) = (x=o.edges, y=o.counts)

midpoints(o::Hist) = midpoints(o.edges)
counts(o::Hist) = o.counts
edges(o::Hist) = o.edges

function area(o::Hist)
    c = o.counts
    e = o.edges
    if isa(e, AbstractRange)
        return step(e) * sum(c)
    else
        return sum((e[i+1] - e[i]) * c[i] for i in 1:length(c))
    end
end

function pdf(o::Hist, y)
    i = binindex(o.edges, y, o.left, o.closed)
    if i < 1 || i > length(o.counts)
        return 0.0
    else
        return o.counts[i] / area(o)
    end
end

function _fit!(o::Hist, y)
    i = binindex(o.edges, y, o.left, o.closed)
    if 1 ≤ i < length(o.edges)
        o.counts[i] += 1
    else
        o.out[1 + (i > 0)] += 1
    end
end

function _merge!(o::Hist, o2::Hist)
    if o.edges == o2.edges
        for j in eachindex(o.counts)
            o.counts[j] += o2.counts[j]
        end
    else
        @warn("Histogram edges are not aligned.  Merging is approximate.")
        for (yi, wi) in zip(midpoints(o2.edges), o2.counts)
            for k in 1:wi
                _fit!(o, yi)
            end
        end
    end
    for j in eachindex(o.out)
        o.out[j] += o2.out[j]
    end
end



#-----------------------------------------------------------------------# ExpandingHist
const ExpandableRange = Union{StepRange, StepRangeLen, LinRange}

"""
    ExpandingHist(nbins)

An adaptive histogram where the bin edges keep doubling in size in order to contain every observation.
`nbins` must be an even number.  Bins are left-closed and the rightmost bin is closed, e.g.

- `[a, b)`, `[b, c)`, `[c, d]`

# Example 
    o = fit!(ExpandingHist(200), randn(10^6))

    using Plots
    plot(o)

# Details 

How `ExpandingHist` works is best understood through example.  Suppose we start with a histogram 
of edges/counts as follows:

```
|1|2|5|3|2|
```

- Now we observe a data point that is not contained in the bin edges:

```
|1|2|5|3|2|       *
```

- In order to contain the point, the range of the edges doubles in the direction of the new 
  data point and adjacent bins merge their counts:

```
|1|2|5|3|2|       *
 \\ / \\ / \\ /      ↓
  ↓   ↓   ↓       ↓ 
| 3 | 8 | 2 | 0 | 1 | 
```

- Note that multiple iterations of bin-doubling may occur until the new point is contained by the 
  bin edges. 
"""
mutable struct ExpandingHist{T, R <: StepRangeLen} <: HistogramStat{T}
    edges::R
    counts::Vector{Int}
    n::Int
    function ExpandingHist(init::R, T::Type=Number) where {R <: ExpandableRange}
        new{T, R}(init, zeros(Int, length(init) - 1), 0)
    end
end
function ExpandingHist(b::Int)
    @assert iseven(b)
    ExpandingHist(range(0, stop=0, length = b + 1), Number)
end
value(o::ExpandingHist) = (x=o.edges, y=o.counts)

Base.show(io::IO, o::ExpandingHist) = print(io, "ExpandingHist | n = $(nobs(o)) | nbins = $(length(o.counts))")

midpoints(o::ExpandingHist) = midpoints(o.edges)
counts(o::ExpandingHist) = o.counts
edges(o::ExpandingHist) = o.edges

function _fit!(o::ExpandingHist, y)
    isfinite(y) || error("ExpandingHist requires finite values.  Found $y.")
    o.n += 1 

    # init
    @inbounds if nobs(o) == 1
        o.edges = range(y, stop=y, length=length(o.edges))
        o.counts[1] = 1
    elseif step(o.edges) == 0.0
        a = o.edges[1]
        if y == a 
            o.counts[1] += 1
        elseif y < a 
            o.edges = range(y, stop=a, length=length(o.edges))
            o.counts[end] = o.counts[1]
            o.counts[1] = 1
        else
            o.edges = range(a, stop=y, length=length(o.edges))
            o.counts[end] = 1
        end
    else
        expand!(o, y)
        i = binindex(o.edges, y, true, true)
        o.counts[i] += 1
    end
end

function expand!(o::ExpandingHist, y)
    a, b = extrema(o.edges)
    w = b - a
    w = w == 0.0 ? y - a : w
    halfnbin = round(Int, length(o.counts) / 2)
    @inbounds if y > b  # find K such that y <= a + 2^K * w
        K = ceil(Int, log2((y - a) / w))
        C = 2 ^ K
        o.edges = range(a, stop = a + C*w, length=length(o.edges))
        for _ in 1:min(K, halfnbin)
            for i in eachindex(o.counts)
                o.counts[i] = i ≤ halfnbin ? sum(view(o.counts, (2i-1):(2i))) : 0
            end
        end
    elseif y < a # find K such that y >= b - 2^K * w
        K = ceil(Int, log2((b - y) / w))
        C = 2 ^ K
        o.edges = range(b - C*w, stop = b, length=length(o.edges))
        for _ in 1:min(K, halfnbin)
            n = length(o.counts)
            for i in 0:(length(o.counts) - 1)
                rng = (n-2i-1):(n-2i)
                o.counts[end-i] = i+1 ≤ halfnbin ? sum(view(o.counts, rng)) : 0
            end
        end
    end
end