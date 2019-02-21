#-----------------------------------------------------------------------# common 
abstract type HistogramStat{T} <: OnlineStat{T} end

# Index of `edges` that `y` belongs in, depending on if bins are `left` closed and if
# the bin on the end is `closed` instead of half-open.
function binindex(edges::AbstractVector, y, left::Bool, closed::Bool)
    a, b = extrema(edges)
    if y < a 
        0
    elseif y > b 
        length(edges)
    elseif y == a && (left || closed)
        1
    elseif y == b && (!left || closed)
        length(edges) - 1
    elseif left 
        if isa(edges, AbstractRange)
            floor(Int, (y - a) / step(edges)) + 1
        else
            searchsortedlast(edges, y)
        end
    else
        if isa(edges, AbstractRange)
            ceil(Int, (y - a) / step(edges))
        else
            searchsortedfirst(edges, y) - 1
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

    function Hist(edges::R, T::Type = eltype(edges); left::Bool=true, closed::Bool = true) where {R<:AbstractVector}           
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
        @warn("Histogram edges do not align.  Merging is approximate.")
        for (yi, wi) in zip(midpoints(o2.edges), o2.counts)
            for k in 1:wi 
                _fit!(o, yi)
            end
        end
    end
end



#-----------------------------------------------------------------------# ExpandingHist
const ExpandableRange = Union{StepRange, StepRangeLen, LinRange}

mutable struct ExpandingHist{T, R <: StepRangeLen} <: HistogramStat{T}
    edges::R
    counts::Vector{Int}
    left::Bool
    n::Int
    function ExpandingHist(init::R, T::Type=Number; left::Bool = true) where {R <: ExpandableRange}
        new{T, R}(init, zeros(Int, length(init) - 1), left, 0)
    end
end
function ExpandingHist(b::Int; left::Bool=true) 
    ExpandingHist(range(0, stop = 0, length = b + 1), Number; left=left)
end

midpoints(o::ExpandingHist) = midpoints(o.edges)
counts(o::ExpandingHist) = o.counts
edges(o::ExpandingHist) = o.edges

function Base.in(y, o::ExpandingHist) 
    a, b = extrema(o.edges)
    o.left ? (a ≤ y < b) : (a < y ≤ b)
end

function _fit!(o::ExpandingHist, y)
    o.n += 1

    # init
    if nobs(o) == 1
        o.edges = range(y, stop=y, length=length(o.edges))
    elseif nobs(o) == 2
        a, b = extrema(o.edges)
        ey = eps(float(y))
        o.edges = range(min(a,y) - ey, stop=max(b, y) + ey, length=length(o.edges))
    end

    expand!(o, y)
    o.counts[binindex(o.edges, y, o.left, false)] += 1
end

function expand!(o::ExpandingHist, y)
    a, b = extrema(o.edges)
    if y > b  # find C such that y <= a + 2^C * (b - a)
        C = ceil(Int, log2((y - a) / (b - a)))
        o.edges = range(a, stop = a + 2^C * (b - a), length = length(o.edges))
    elseif y < a  # find C such that y >= b - 2^C * (b - a)
        C = ceil(Int, log2((b - y) / (b - a)))
        o.edges = range(b - 2^C * (b - a), stop = b, length = length(o.edges))
    end
end


# function adapt!(o::Hist, y)
#     y in o && return nothing
    
#     a, b = extrema(o.edges)
#     w = b - a

#     # number of widths to extend to the left
#     vl = (a - y) / w 
#     n_widths_l = if vl < 0
#         0
#     elseif o.left || o.closed
#         ceil(Int, (a - y) / w)
#     else
#         v = (a - y) / w
#         ceil(Int, v) + isinteger(v)
#     end

#     # number of widths to extend to the right
#     vr = (y - b) / w 
#     n_widths_r = if vr < 0
#         0
#     elseif !o.left || o.closed 
#         ceil(Int, (y - b) / w)
#     else
#         v = (y - b) / w
#         ceil(Int, v) + isinteger(v)
#     end

#     for i in 1:n_widths_l
#         o.edges = extendleft(o.edges)
#         collapseright!(o.counts)
#     end
#     for i in 1:n_widths_r 
#         o.edges = extendright(o.edges)
#         collapseleft!(o.counts)
#     end
#     nothing
# end

# function Base.in(y, o::Hist)
#     a, b = extrema(o.edges)
#     if o.left 
#         return o.closed ? (a ≤ y ≤ b) : (a ≤ y < b)
#     else
#         return o.closed ? (a ≤ y ≤ b) : (a < y ≤ b)
#     end
# end

# function collapseleft!(x)
#     for i in eachindex(x)
#         j = 2i - 1
#         if j <= length(x)
#             x[i] = x[j]
#             if j < length(x) 
#                 x[i] += x[j + 1]
#             end
#         else
#             x[i] = 0
#         end
#     end
# end
# function collapseright!(x)
#     for i in reverse(eachindex(x))
#         j = 2i - length(x)
#         if j >= 1
#             x[i] = x[j]
#             if j > 1
#                 x[i] += x[j - 1]
#             end
#         else
#             x[i] = 0
#         end
#     end
# end

# function extendleft(rng::StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}})
#     a, b = extrema(rng)
#     range(2a - b, stop = b, length = length(rng))
# end
# function extendright(rng::StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}})
#     a, b = extrema(rng)
#     range(a, stop = 2b - a, length = length(rng))
# end


# function extendleft(rng::StepRange)
#     a, b = extrema(rng)
#     (2a - b):step(rng):b
# end
# function extendright(rng::StepRange)
#     a, b = extrema(rng)
#     a:step(rng):(2b - a)
# end

# extendleft(rng) = error("Histogram cannot adapt with bin edges of type ", typeof(rng))
# extendright(rng) = extendleft(rng)







#-----------------------------------------------------------------------# KHist
struct KHistBin{T}
    loc::T 
    count::Int
end
Base.isless(a::KHistBin, b::KHistBin) = isless(a.loc, b.loc)
function Base.merge(a::KHistBin, b::KHistBin)
    n = a.count + b.count 
    KHistBin(smooth(a.loc, b.loc, b.count / n), n)
end
xy(o::KHistBin) = o.loc, o.count

@deprecate Hist(b::Int) KHist(b::Int)


"""
    KHist(k::Int)

Estimate the probability density of a univariate distribution at `k` approximately 
equally-spaced points.
    
Ref: [http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf](http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf)

# Example 

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
"""
struct KHist{T, E<:Extrema{T}} <: HistogramStat{Number}
    bins::Vector{KHistBin{T}}
    b::Int
    ex::E
end
KHist(b::Int, T::Type = Float64) = KHist(KHistBin{T}[], b, Extrema(T))

midpoints(o::KHist) = getfield.(o.bins, :loc)
counts(o::KHist) = getfield.(o.bins, :count)
edges(o::KHist) = vcat(minimum(o.ex), midpoints(getfield.(o.bins, :loc)), maximum(o.ex))

nobs(o::KHist) = isempty(o.bins) ? 0 : sum(x -> x.count, o.bins)

xy(o::KHist) = getfield.(o.bins, :loc), getfield.(o.bins, :count)

Base.extrema(o::KHist) = extrema(o.ex)

function value(o::KHist) 
    x, y = xy(o)
    a, b = extrema(o.ex)
    if !isempty(x)
        if x[1] != a && y[1] != 1
            pushfirst!(x, a)
            pushfirst!(y, 1)
        end
        if x[end] != b && y[end] != 1
            push!(x, b)
            push!(y, 1)
        end
    end
    (x=x, y=y)
end

_fit!(o::KHist{T}, y) where {T} = push!(o, KHistBin(T(y), 1))

function Base.push!(o::KHist, y::KHistBin) 
    fit!(o.ex, y.loc)
    insert!(o.bins, searchsortedfirst(o.bins, y), y)
    if length(o.bins) > o.b 
        mindiff, i = Inf, 0
        for k in Base.OneTo(length(o.bins) - 1)
            diff = o.bins[k + 1].loc - o.bins[k].loc
            if diff < mindiff 
                mindiff, i = diff, k
            end
        end
        o.bins[i] = merge(o.bins[i], o.bins[i + 1])
        deleteat!(o.bins, i + 1)
    end
end

function _merge!(a::KHist, b::KHist)
    merge!(a.ex, b.ex)
    for bin in b.bins
        push!(a, bin)
    end
end

function area(o::KHist, ind = length(o.bins) - 1)
    x, y = value(o)
    out = 0.0
    for i in Base.OneTo(ind)
        out += (x[i+1] - x[i]) * middle(y[i+1], y[i])
    end
    out
end

# based on linear interpolation
function pdf(o::KHist, x::Number)
    a, b = extrema(o.ex)
    firstbin = o.bins[1]
    lastbin = o.bins[end]

    # a ≤ firstbin.loc ≤ lastbin.loc ≤ b
    if firstbin.loc < x < lastbin.loc
        i = searchsortedfirst(o.bins, KHistBin(x, 0))
        x1, y1 = xy(o.bins[i - 1])
        x2, y2 = xy(o.bins[i])
        return smooth(y1, y2, (x - x1) / (x2 - x1)) / area(o)
    elseif a < x ≤ firstbin.loc
        x1, y1 = a, 1
        x2, y2 = xy(firstbin)
        return smooth(y1, y2, (x - x1) / (x2 - x1)) / area(o)
    elseif lastbin.loc ≤ x < b 
        x1, y1 = xy(lastbin)
        x2, y2 = b, 1
        return smooth(y1, y2, (x - x1) / (x2 - x1)) / area(o)
    elseif x == a || x == b
        return 1 / area(o)
    else
        return 0.0
    end
end

function cdf(o::KHist, x::Number)
    a, b = extrema(o.ex)
    if x < a 
        return 0.0
    elseif x == a 
        return o.bins[1].count / area(o)
    elseif x ≥ b
        return 1.0
    else
        i = searchsortedfirst(o.bins, KHistBin(x, 0))
        x1, y1 = xy(o.bins[i - 1])
        x2, y2 = xy(o.bins[i])
        h = smooth(y1, y2, (x2 - x) / (x2 - x1))
        return (area(o, i - 2) + (x - x1) * h) / area(o)
    end
end