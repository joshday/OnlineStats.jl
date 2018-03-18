abstract type HistAlgorithm{N} <: Algorithm end
Base.show(io::IO, o::HistAlgorithm) = print(io, name(o, false, false))

#-----------------------------------------------------------------------# Hist 
"""
    Hist(nbins)
    Hist(edges)

Calculate a histogram over fixed `edges` or adaptive `nbins`.
"""
struct Hist{N, H <: HistAlgorithm{N}} <: OnlineStat{N}
    alg::H 
    Hist{H}(alg::H) where {N, H<:HistAlgorithm{N}} = new{N, H}(alg)
end
Hist(args...; kw...) = (alg = make_alg(args...; kw...); Hist{typeof(alg)}(alg))

for f in [:nobs, :counts, :midpoints, :edges]
    @eval $f(o::Hist) = $f(o.alg)
end

Base.show(io::IO, o::Hist) = print(io, "Hist: ", o.alg)
_fit!(o::Hist, y) = _fit!(o.alg, y)
Base.merge!(o::Hist, o2::Hist) = merge!(o.alg, o2.alg)
value(o::Hist) = (midpoints(o), counts(o))

split_candidates(o::Hist) = midpoints(o)
Base.mean(o::Hist) = mean(midpoints(o), fweights(counts(o)))
Base.var(o::Hist) = var(midpoints(o), fweights(counts(o)); corrected=true)
Base.std(o::Hist) = sqrt(var(o))
Base.median(o::Hist) = quantile(o, .5)
function Base.extrema(o::Hist) 
    mids, counts = value(o)
    inds = findall(x->x!=0, counts)  # filter out zero weights 
    mids[inds[1]], mids[inds[end]]
end
function Base.quantile(o::Hist, p = [0, .25, .5, .75, 1]) 
    mids, counts = value(o)
    inds = findall(x->x!=0, counts)  # filter out zero weights
    quantile(mids[inds], fweights(counts[inds]), p)
end

#-----------------------------------------------------------------------# FixedBins
mutable struct FixedBins{closed, E <: AbstractVector} <: HistAlgorithm{0}
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

function Base.merge!(o::FixedBins, o2::FixedBins) 
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
        e = o.edges
        if isa(e, AbstractRange)
            area = step(e) * sum(c)
        else
            area = sum((e[i+1] - e[i]) * c[i] for i in 1:length(c))
        end
        return c[binidx] / area
    end
end

#-----------------------------------------------------------------------# AdaptiveBins
"""
Calculate a histogram adaptively.

Ref: [http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf](http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf)
"""
struct AdaptiveBins{T} <: HistAlgorithm{0} 
    value::Vector{Pair{T, Int}}
    b::Int
    ex::Extrema{T}
end
make_alg(b::Int, T::Type=Float64) = AdaptiveBins(Pair{T, Int}[], b, Extrema(T))
make_alg(T::Type, b::Int) = AdaptiveBins(Pair{T, Int}[], b, Extrema(T))
midpoints(o::AdaptiveBins) = first.(o.value)
counts(o::AdaptiveBins) = last.(o.value)
nobs(o::AdaptiveBins) = sum(last, o.value)

_fit!(o::AdaptiveBins, y) = (_fit!(o, Pair(y, 1)); _fit!(o.ex, y))

function _fit!(o::AdaptiveBins, y::Pair{<:Any, Int}) 
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

Base.merge!(o::T, o2::T) where {T <: AdaptiveBins} = _fit!.(o, o2.value)

# based on linear interpolation
function pdf(o::AdaptiveBins, y::Number)
    v = o.value
    if isempty(o.value)
        return 0.0
    elseif y ≤ first(first(v)) || y ≥ first(last(v))
        return 0.0
    else 
        i = searchsortedfirst(v, Pair(y, 0)) 
        q1, k1 = v[i-1]
        q2, k2 = v[i]
        area = 0.0
        for i in 1:length(v)-1 
            area += (first(v[i+1]) - first(v[i])) * (last(v[i]) + last(v[i+1]))/2
        end
        return smooth(k1, k2, (y - q1) / (q2 - q1)) / area
    end
end


# # Algorithm 3: Sum Procedure
# # Estimated number of points in interval [-∞, b]
# function Base.sum(o::AdaptiveBins, b::Real)::Float64
#     if isempty(o.value)
#         return 0.0
#     elseif b ≤ first(first(o.value))
#         return 0.0
#     elseif b ≥ first(last(o.value))
#         return Float64(nobs(o))
#     else
#         # find i such that p(i) ≤ b < p(i+1)
#         i = searchsortedfirst(o.value, Pair(b, 1)) - 1
#         p1, m1 = o.value[i]
#         p2, m2 = o.value[i + 1]
#         mb = m1 + (m2 - m1) * (b - p1) / (p2 - p1)
#         s = .5 * (m1 + mb) * (b - p1) / (p2 - p1)
#         return s + sum(last.(o.value[1:(i-1)])) + m1 / 2
#     end
# end