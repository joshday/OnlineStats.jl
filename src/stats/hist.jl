abstract type HistAlgorithm{N} <: Algorithm end
Base.show(io::IO, o::HistAlgorithm) = print(io, name(o, false, false))
make_alg(o::HistAlgorithm) = o

#-----------------------------------------------------------------------# Hist 
"""
    Hist(nbins)
    Hist(edges)

Calculate a histogram over fixed `edges` or adaptive `nbins`.

# Example

    using OnlineStats, Statistics
    y = randn(10^6)

    o = fit!(Hist(20), y)
    quantile(o)
    mean(o)
    var(o)
    std(o)
    extrema(o)
    OnlineStats.pdf(o, 0.0)
    OnlineStats.cdf(o, 0.0)
"""
struct Hist{N, H <: HistAlgorithm{N}} <: OnlineStat{N}
    alg::H 
    Hist{H}(alg::H) where {N, H<:HistAlgorithm{N}} = new{N, H}(alg)
end
Hist(args...; kw...) = (alg = make_alg(args...; kw...); Hist{typeof(alg)}(alg))

for f in [:nobs, :counts, :midpoints, :edges, :area]
    @eval $f(o::Hist) = $f(o.alg)
end
for f in [:(_fit!), :pdf, :cdf, :(Base.getindex)]
    @eval $f(o::Hist, y) = $f(o.alg, y) 
end

# Base.show(io::IO, o::Hist) = print(io, "Hist: ", o.alg)
_merge!(o::Hist, o2::Hist) = _merge!(o.alg, o2.alg)
value(o::Hist) = (midpoints(o), counts(o))

split_candidates(o::Hist) = midpoints(o)
Statistics.mean(o::Hist) = mean(midpoints(o), fweights(counts(o)))
Statistics.var(o::Hist) = var(midpoints(o), fweights(counts(o)); corrected=true)
Statistics.std(o::Hist) = sqrt(var(o))
Statistics.median(o::Hist) = quantile(o, .5)
function Base.extrema(o::Hist) 
    mids, counts = value(o)
    inds = findall(x->x!=0, counts)  # filter out zero weights 
    mids[inds[1]], mids[inds[end]]
end
function Statistics.quantile(o::Hist, p = [0, .25, .5, .75, 1]) 
    mids, counts = value(o)
    inds = findall(x->x!=0, counts)  # filter out zero weights
    quantile(mids[inds], fweights(counts[inds]), p)
end

#-----------------------------------------------------------------------# FixedBins2 
# left-closed only
mutable struct FixedBins2{E1, E2} <: HistAlgorithm{VectorOb}
    x::E1 
    y::E2 
    z::Matrix{Int}
    out::Int
end
function make_alg(e::AbstractVector, e2::AbstractVector; kw...) 
    FixedBins2(e, e2, zeros(Int, length(e2), length(e)), 0)
end
nobs(o::FixedBins2) = sum(o.z) + o.out

value(o::Hist{N, <:FixedBins2}) where {N} = (o.alg.x, o.alg.y, o.alg.z)

function _fit!(o::FixedBins2, xy)
    x, y = xy 
    if x > maximum(o.x) || x < minimum(o.x) || y > maximum(o.y) || y < minimum(o.y)
        o.out += 1
    else
        j = searchsortedfirst(o.x, x)
        i = searchsortedfirst(o.y, y)
        o.z[i-1, j-1] += 1
    end 
end

#-----------------------------------------------------------------------# FixedBins
mutable struct FixedBins{closed, E <: AbstractVector} <: HistAlgorithm{Number}
    edges::E
    counts::Vector{Int}
    out::Int

    function FixedBins{closed,E}(edges::E, counts::Vector{Int},
                                 out::Int) where {E<:AbstractVector,closed}
        closed in [:left, :right] || error("closed must be left or right")
        length(edges) == length(counts) + 1 ||
            error("Histogram edge vectors must be 1 longer than corresponding count vectors")
        issorted(edges) || error("Histogram edge vectors must be sorted in ascending order")
        new{closed,E}(edges, counts, out)
    end
end
Base.@pure FixedBins(edges::AbstractVector, counts::Vector{Int}, out::Int; closed::Symbol = :left) =
    FixedBins{closed,typeof(edges)}(edges, counts, out)

make_alg(e::AbstractVector; kw...) = FixedBins(e, zeros(Int, length(e) - 1), 0; kw...)
function Base.:(==)(o::FixedBins, o2::FixedBins)
    o.edges == o2.edges && o.counts == o2.counts && o.out == o2.out
end

midpoints(o::FixedBins) = midpoints(o.edges)
counts(o::FixedBins) = o.counts
nobs(o::FixedBins) = sum(o.counts) + o.out
function _fit!(o::FixedBins, y)
    idx = _binindex(o, y)
    if 1 ≤ idx < length(o.edges)
        @inbounds o.counts[idx] += 1
    else
        o.out += 1
    end
end

function _binindex(o::FixedBins{:left}, y)
    edges = o.edges
    a = first(edges)
    if y < a
        return 0
    elseif y == last(edges)
        # right-most bin is a closed interval [a, b]
        return length(edges) - 1
    else
        # other bins are left-closed intervals [a, b)
        if isa(edges, AbstractRange)
            return floor(Int, (y - a) / step(edges)) + 1
        else
            return searchsortedlast(edges, y)
        end
    end
end

function _binindex(o::FixedBins{:right}, y)
    edges = o.edges
    a = first(edges)
    if y < a
        return 0
    elseif y == first(edges)
        # left-most bin is a closed interval [a, b]
        return 1
    else
        # other bins are right-closed intervals (a, b]
        if isa(edges, AbstractRange)
            return ceil(Int, (y - a) / step(edges))
        else
            return searchsortedfirst(edges, y) - 1
        end
    end
end

function _merge!(o::FixedBins, o2::FixedBins) 
    if o.edges == o2.edges 
        for j in eachindex(o.counts)
            o.counts[j] += o2.counts[j]
        end
    else
        for (yi, wi) in zip(midpoints(o2), o2.counts)
            for k in 1:wi 
                _fit!(o, yi)
            end
        end
    end
end

# No linear interpolation (in contrast to AdaptiveBins)
function pdf(o::FixedBins, y::Real)
    binidx = _binindex(o, y)
    c = o.counts
    if binidx < 1 || binidx > length(c)
        return 0.0
    else
        return c[binidx] / area(o)
    end
end

function area(o::FixedBins) 
    c = o.counts 
    e = o.edges
    if isa(e, AbstractRange)
        return step(e) * sum(c)
    else
        return sum((e[i+1] - e[i]) * c[i] for i in 1:length(c))
    end
end

#-----------------------------------------------------------------------# P2Bins 
mutable struct P2Bins <: HistAlgorithm{Number}
    q::Vector{Float64}
    n::Vector{Int}
    nobs::Int
    P2Bins(b::Int) = new(zeros(b+1), collect(1:(b+1)), 0)
end
nobs(o::P2Bins) = o.nobs

# https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf     page 1084
function _fit!(o::P2Bins, y)
    q = o.q 
    n = o.n
    o.nobs += 1 
    b = length(o.q) - 1
    # A
    o.nobs <= length(o.q) && (o.q[o.nobs] = y)
    o.nobs == length(o.q) && sort!(o.q)
    # B1 
    k = if y < o.q[1]
        o.q[1] = y 
        1
    elseif y > o.q[end]
        o.q[end] = y 
        b
    elseif o.q[end-1] <= y <= o.q[end]
        b
    else
        searchsortedfirst(o.q, y)
    end
    # B2 
    for i in (k+1):length(o.q)
        o.n[i] += 1
    end
    # B3 
    for i in 2:b
        nprime = 1 + (i-1) * (nobs(o)-1) / b
        di = nprime - n[i]
        if (di >= 1 && n[i+1] - n[i] > 1) || (i <= -1 && n[i-1] - n[i] < -1)
            d = Int(sign(di))
            qiprime = parabolic_prediction(q[i-1],q[i],q[i+1],n[i-1],n[i],n[i+1],d)
            if q[i-1] < qiprime < q[i]
                q[i] = qiprime
            else
                q[i] += d * (q[i+d] - q[i]) / (n[i+d] - n[i])
            end
            o.n[i] += d
        end
    end
end

# return qi, ni
function parabolic_prediction(q1, q2, q3, n1, n2, n3, d)
    qi = q2 + d / (n3 - n1)
    qi *= ((n2-n1+d) * (q3-q2) / (n3-n2) + (n3-n2-d) * (q2-q1) / (n2-n1))
    qi
end

midpoints(o::P2Bins) = o.q
counts(o::P2Bins) = o.n ./ nobs(o)

#-----------------------------------------------------------------------# AdaptiveBins
"""
Calculate a histogram adaptively.

Ref: [http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf](http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf)
"""
struct AdaptiveBins <: HistAlgorithm{Number} 
    value::Vector{Pair{Float64, Int}}
    b::Int
    ex::Extrema{Float64}
end
make_alg(b::Int) = AdaptiveBins(Pair{Float64, Int}[], b, Extrema(Float64))
midpoints(o::AdaptiveBins) = first.(o.value)
counts(o::AdaptiveBins) = last.(o.value)
nobs(o::AdaptiveBins) = isempty(o.value) ? 0 : sum(last, o.value)
function Base.:(==)(a::T, b::T) where {T<:AdaptiveBins}
    (a.value == b.value) && (a.b == b.b) && (a.ex == b.ex)
end
Base.extrema(o::Hist{<:Any, <:AdaptiveBins}) = extrema(o.alg.ex)


_fit!(o::AdaptiveBins, y) = _fit!(o, Pair(y, 1))

function _fit!(o::AdaptiveBins, y::Pair{<:Any, Int}) 
    fit!(o.ex, first(y))
    v = o.value
    i = searchsortedfirst(v, y)
    insert!(v, i, y)
    if length(v) > o.b 
        # find minimum difference
        i = 0 
        mindiff = Inf 
        for k in 1:(length(v) - 1)
            @inbounds diff = first(v[k + 1]) - first(v[k])
            if diff < mindiff 
                mindiff = diff 
                i = k 
            end
        end
        # merge bins i, i+1
        q2, k2 = v[i + 1]
        if k2 > 0
            q1, k1 = v[i]
            k3 = k1 + k2
            v[i] = Pair(smooth(q1, q2, k2 / k3), k3)
        end
        deleteat!(o.value, i + 1)
    end
end

function _merge!(o::T, o2::T) where {T <: AdaptiveBins} 
    for v in o2.value
        _fit!(o, v)
    end
    fit!(o.ex, extrema(o2.ex))
end

function Base.getindex(o::AdaptiveBins, i)
    if i == 0 
        return Pair(minimum(o.ex), 0)
    elseif i == (length(o.value) + 1) 
        return Pair(maximum(o.ex), 0)
    else 
        return o.value[i]
    end
end

# based on linear interpolation
function pdf(o::AdaptiveBins, x::Number)
    v = o.value
    if x ≤ minimum(o.ex)
        return 0.0 
    elseif x ≥ maximum(o.ex)
        return 0.0 
    else 
        i = searchsortedfirst(v, Pair(x, 0))
        x1, y1 = o[i - 1]
        x2, y2 = o[i]
        return smooth(y1, y2, (x - x1) / (x2 - x1)) / area(o)
    end
end

function cdf(o::AdaptiveBins, x::Number)
    if x ≤ minimum(o.ex)
        return 0.0 
    elseif x ≥ maximum(o.ex)
        return 1.0 
    else
        i = searchsortedfirst(o.value, Pair(x, 0))
        x1, y1 = o[i - 1]
        x2, y2 = o[i]
        w = x - x1
        h = smooth(y1, y2, (x2 - x) / (x2 - x1))
        return (area(o, i-2) + w * h) / area(o)
    end
end

function area(o::AdaptiveBins, ind = length(o.value))
    out = 0.0 
    for i in 1:ind
        w = first(o[i+1]) - first(o[i])
        h = (last(o[i+1]) + last(o[i])) / 2
        out += h * w
    end
    out
end


# #-----------------------------------------------------------------------# Hexbin 
# struct HexBin{E1,E2} <: HistAlgorithm{VectorOb}
#     x::E1 
#     y::E2 
#     z::Matrix{Int}
#     nout::Int
# end
# HexBin(x,y) = HexBin(x, y, zeros(Int, length(y), length(x)), 0)
# Base.show(io::IO, o::HexBin) = print(io, "HexBin(x_edge = $(o.x), y_edge = $(o.y))")

# nobs(o::HexBin) = sum(o.z) + o.out

# function _fit!(o::HexBin, xy)
#     x, y = xy 
#     if x > maximum(o.x) || x < minimum(o.x) || y > maximum(o.y) || y < minimum(o.y)
#         o.out += 1
#     else
#         j = searchsortedfirst(o.x, x) - 1
#         i = searchsortedfirst(o.y, y) - 1
#         if i == 1
      
#         else 
#         end
#         o.z[i, j] += 1
#     end 
# end