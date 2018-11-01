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

# requires: midpoints(o), counts(o)
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



#-----------------------------------------------------------------------# HeatMap
"""
    Heatmap(xedges, yedges; left = true, closed = true)

Create a two dimensional histogram with the bin partition created by `xedges` and `yedges`.  
When fitting a new observation, the first value will be associated with X, the second with Y.

- If `left`, the bins will be left-closed.
- If `closed`, the bins on the ends will be closed.  See [Hist](@ref).

# Example 

    o = fit!(HeatMap(-5:.1:5, -5:.1:5), eachrow(randn(10^5, 2)))

    using Plots
    plot(o)
"""
mutable struct HeatMap{EX, EY} <: OnlineStat{XY}
    xedges::EX 
    yedges::EY
    counts::Matrix{Int}
    out::Int
    left::Bool 
    closed::Bool

    function HeatMap(x::T, y::S; left::Bool=true, closed::Bool=true) where {T<:AbstractVector,S<:AbstractVector}
        new{T,S}(x,y, zeros(Int, length(x)-1, length(y)-1), 0, left, closed)
    end
end
nobs(o::HeatMap) = sum(o.counts) + o.out
value(o::HeatMap) = (x=o.xedges, y=o.yedges, z=o.counts)

function _fit!(o::HeatMap, xy)
    i = binindex(o.xedges, xy[1], o.left, o.closed)
    if 1 ≤ i < length(o.xedges)
        j = binindex(o.yedges, xy[2], o.left, o.closed)
        if 1 ≤ j < length(o.yedges)
            o.counts[i, j] += 1
        else
            o.out += 1
        end
    else
        o.out += 1
    end
end

function _merge!(a::HeatMap, b::HeatMap)
    if (a.xedges == b.xedges) && (a.yedges == b.yedges) && (a.left == b.left) && (a.closed == b.closed)
        a.out += b.out
        a.counts .+= b.counts
    else 
        @warn "HeatMaps differ in edges or direction of bins being closed.  No merging occurred."
    end
end


# #-----------------------------------------------------------------------# ExpandingHist
# const ExpandableRange = Union{StepRange, StepRangeLen, LinRange}

# mutable struct ExpandingHist{T, R <: ExpandableRange} <: OnlineStat{T}
#     edges::R
#     counts::Vector{Int}
#     left::Bool
#     n::Int
#     function ExpandingHist(init::R, T::Type=Number; left::Bool = true) where {R <: ExpandableRange}
#         new{T, R}(init, zeros(Int, length(init) - 1), left, 0)
#     end
# end
# function ExpandingHist(b::Int; left::Bool=true) 
#     new(range(0, stop = 1, length = b + 1), zeros(Int, b), left, 0)
# end

# function Base.in(x, o::ExpandingHist) 
#     a, b = extrema(o.edges)
#     o.left ? (a ≤ y < b) : (a < y ≤ b)
# end



# function _fit!(o::ExpandingHist, y)
#     if (o.n += 1) < 3
#         o.edges = _init_edges(o.edges, y)
#     end
# end

# function _init_edges(r::StepRange)

# end




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
struct KHist{T} <: HistogramStat{Number}
    bins::Vector{KHistBin{T}}
    b::Int
    ex::Extrema{T}
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

_fit!(o::KHist, y) = push!(o, KHistBin(y, 1))

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
    if x ≤ minimum(o.ex)
        return 0.0 
    elseif x ≥ maximum(o.ex)
        return 0.0 
    else 
        i = searchsortedfirst(o.bins, KHistBin(x, 0))
        x1, y1 = xy(o.bins[i - 1])
        x2, y2 = xy(o.bins[i])
        return smooth(y1, y2, (x - x1) / (x2 - x1)) / area(o)
    end
end

function cdf(o::KHist, x::Number)
    if x ≤ minimum(o.ex)
        return 0.0 
    elseif x ≥ maximum(o.ex)
        return 1.0 
    else
        i = searchsortedfirst(o.bins, KHistBin(x, 0))
        x1, y1 = o.bins[i - 1].loc, o.bins[i-1].count
        x2, y2 = o.bins[i].loc, o.bins[i].count
        w = x - x1
        h = smooth(y1, y2, (x2 - x) / (x2 - x1))
        return (area(o, i-2) + w * h) / area(o)
    end
end





# #-----------------------------------------------------------------------# P2Bins 
# mutable struct P2Bins <: HistAlgorithm{Number}
#     q::Vector{Float64}
#     n::Vector{Int}
#     nobs::Int
#     P2Bins(b::Int) = new(zeros(b+1), collect(1:(b+1)), 0)
# end
# nobs(o::P2Bins) = o.nobs

# # https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf     page 1084
# function _fit!(o::P2Bins, y)
#     q = o.q 
#     n = o.n
#     o.nobs += 1 
#     b = length(o.q) - 1
#     # A
#     o.nobs <= length(o.q) && (o.q[o.nobs] = y)
#     o.nobs == length(o.q) && sort!(o.q)
#     # B1 
#     k = if y < o.q[1]
#         o.q[1] = y 
#         1
#     elseif y > o.q[end]
#         o.q[end] = y 
#         b
#     elseif o.q[end-1] <= y <= o.q[end]
#         b
#     else
#         searchsortedfirst(o.q, y)
#     end
#     # B2 
#     for i in (k+1):length(o.q)
#         o.n[i] += 1
#     end
#     # B3 
#     for i in 2:b
#         nprime = 1 + (i-1) * (nobs(o)-1) / b
#         di = nprime - n[i]
#         if (di >= 1 && n[i+1] - n[i] > 1) || (i <= -1 && n[i-1] - n[i] < -1)
#             d = Int(sign(di))
#             qiprime = parabolic_prediction(q[i-1],q[i],q[i+1],n[i-1],n[i],n[i+1],d)
#             if q[i-1] < qiprime < q[i]
#                 q[i] = qiprime
#             else
#                 q[i] += d * (q[i+d] - q[i]) / (n[i+d] - n[i])
#             end
#             o.n[i] += d
#         end
#     end
# end

# # return qi, ni
# function parabolic_prediction(q1, q2, q3, n1, n2, n3, d)
#     qi = q2 + d / (n3 - n1)
#     qi *= ((n2-n1+d) * (q3-q2) / (n3-n2) + (n3-n2-d) * (q2-q1) / (n2-n1))
#     qi
# end

# midpoints(o::P2Bins) = o.q
# counts(o::P2Bins) = o.n ./ nobs(o)

# #-----------------------------------------------------------------------# AdaptiveBins
# """
# Calculate a histogram adaptively.

# Ref: [http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf](http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf)
# """
# struct AdaptiveBins <: HistAlgorithm{Number} 
#     value::Vector{Pair{Float64, Int}}
#     b::Int
#     ex::Extrema{Float64}
# end
# make_alg(b::Int) = AdaptiveBins(Pair{Float64, Int}[], b, Extrema(Float64))
# midpoints(o::AdaptiveBins) = first.(o.value)
# counts(o::AdaptiveBins) = last.(o.value)
# nobs(o::AdaptiveBins) = isempty(o.value) ? 0 : sum(last, o.value)
# function Base.:(==)(a::T, b::T) where {T<:AdaptiveBins}
#     (a.value == b.value) && (a.b == b.b) && (a.ex == b.ex)
# end
# Base.extrema(o::Hist{<:Any, <:AdaptiveBins}) = extrema(o.alg.ex)


# _fit!(o::AdaptiveBins, y) = _fit!(o, Pair(y, 1))

# function _fit!(o::AdaptiveBins, y::Pair{<:Any, Int}) 
#     fit!(o.ex, first(y))
#     v = o.value
#     i = searchsortedfirst(v, y)
#     insert!(v, i, y)
#     if length(v) > o.b 
#         # find minimum difference
#         i = 0 
#         mindiff = Inf 
#         for k in 1:(length(v) - 1)
#             @inbounds diff = first(v[k + 1]) - first(v[k])
#             if diff < mindiff 
#                 mindiff = diff 
#                 i = k 
#             end
#         end
#         # merge bins i, i+1
#         q2, k2 = v[i + 1]
#         if k2 > 0
#             q1, k1 = v[i]
#             k3 = k1 + k2
#             v[i] = Pair(smooth(q1, q2, k2 / k3), k3)
#         end
#         deleteat!(o.value, i + 1)
#     end
# end

# function _merge!(o::T, o2::T) where {T <: AdaptiveBins} 
#     for v in o2.value
#         _fit!(o, v)
#     end
#     fit!(o.ex, extrema(o2.ex))
# end

# function Base.getindex(o::AdaptiveBins, i)
#     if i == 0 
#         return Pair(minimum(o.ex), 0)
#     elseif i == (length(o.value) + 1) 
#         return Pair(maximum(o.ex), 0)
#     else 
#         return o.value[i]
#     end
# end

# # based on linear interpolation
# function pdf(o::AdaptiveBins, x::Number)
#     v = o.value
#     if x ≤ minimum(o.ex)
#         return 0.0 
#     elseif x ≥ maximum(o.ex)
#         return 0.0 
#     else 
#         i = searchsortedfirst(v, Pair(x, 0))
#         x1, y1 = o[i - 1]
#         x2, y2 = o[i]
#         return smooth(y1, y2, (x - x1) / (x2 - x1)) / area(o)
#     end
# end

# function cdf(o::AdaptiveBins, x::Number)
#     if x ≤ minimum(o.ex)
#         return 0.0 
#     elseif x ≥ maximum(o.ex)
#         return 1.0 
#     else
#         i = searchsortedfirst(o.value, Pair(x, 0))
#         x1, y1 = o[i - 1]
#         x2, y2 = o[i]
#         w = x - x1
#         h = smooth(y1, y2, (x2 - x) / (x2 - x1))
#         return (area(o, i-2) + w * h) / area(o)
#     end
# end

# function area(o::AdaptiveBins, ind = length(o.value))
#     out = 0.0 
#     for i in 1:ind
#         w = first(o[i+1]) - first(o[i])
#         h = middle(last(o[i+1]), last(o[i]))
#         out += h * w
#     end
#     out
# end


# # #-----------------------------------------------------------------------# Hexbin 
# # struct HexBin{E1,E2} <: HistAlgorithm{VectorOb}
# #     x::E1 
# #     y::E2 
# #     z::Matrix{Int}
# #     nout::Int
# # end
# # HexBin(x,y) = HexBin(x, y, zeros(Int, length(y), length(x)), 0)
# # Base.show(io::IO, o::HexBin) = print(io, "HexBin(x_edge = $(o.x), y_edge = $(o.y))")

# # nobs(o::HexBin) = sum(o.z) + o.out

# # function _fit!(o::HexBin, xy)
# #     x, y = xy 
# #     if x > maximum(o.x) || x < minimum(o.x) || y > maximum(o.y) || y < minimum(o.y)
# #         o.out += 1
# #     else
# #         j = searchsortedfirst(o.x, x) - 1
# #         i = searchsortedfirst(o.y, y) - 1
# #         if i == 1
      
# #         else 
# #         end
# #         o.z[i, j] += 1
# #     end 
# # end
