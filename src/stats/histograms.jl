# TODO: Box 2 in https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf

#-----------------------------------------------------------------------# HistAlg
abstract type HistAlg{N} end
Base.show(io::IO, o::HistAlg) = print(io, name(o, false, false))
get_hist_alg(o::HistAlg) = o

# get_hist_alg(args...)     --> HistAlg 
# _midpoints(o)             --> midpoints of bins 
# _counts(o)                --> counts in bins
# nobs
# fit!
# merge!

_midpoints(e::Range) = e[1:length(e) - 1] + 0.5 * step(e)
_midpoints(e::AbstractVector) = [(e[i+1] - e[i]) / 2 for i in 1:length(e) - 1]

#-----------------------------------------------------------------------# Hist
"""
    Hist(e::AbstractVector)
    Hist(b::Int)

Calculate a histogram over bin edges fixed as `e` or adaptively find the best `b` bins.  
The two options use [`FixedBins`](@ref) and [`AdaptiveBins`](@ref), respectively.  
`FixedBins` is much faster, but requires the range of the data to be known before it is 
observed.  `Hist` objects can be used to return approximate summary statistics of the data.

# Example 

    o = Hist(-5:.1:5)
    y = randn(1000)
    Series(y, o)

    # approximate summary statistics
    mean(o)
    var(o)
    std(o)
    median(o)
    extrema(o)
    quantile(o)
"""
struct Hist{N,H<:HistAlg{N}} <: ExactStat{N}
    alg::H

    Hist{H}(alg::H) where {N,H<:HistAlg{N}} = new{N,H}(alg)
end
function Hist(args...; kwargs...)
    alg = get_hist_alg(args...; kwargs...)
    Hist{typeof(alg)}(alg)
end
Base.show(io::IO, o::Hist) = print(io, "Hist: $(o.alg)")
Base.merge!(o::Hist, o2::Hist, γ::Number) = merge!(o.alg, o2.alg, γ)
value(o::Hist) = _midpoints(o), _counts(o)

for f in [:fit!, :nobs, :_midpoints, :_counts, :_pdf, :split_at!, :splitcounts]
    @eval $f(o::Hist, args...) = $f(o.alg, args...)
end

# statistics
Base.mean(o::Hist) = mean(_midpoints(o), fweights(_counts(o)))
Base.var(o::Hist) = var(_midpoints(o), fweights(_counts(o)); corrected=true)
Base.std(o::Hist) = sqrt(var(o))
Base.median(o::Hist) = quantile(o, .5)
function Base.extrema(o::Hist) 
    mids, counts = value(o)
    inds = find(counts)  # filter out zero weights 
    mids[inds[1]], mids[inds[end]]
end
function Base.quantile(o::Hist, p = [0, .25, .5, .75, 1]) 
    mids, counts = value(o)
    inds = find(counts)  # filter out zero weights
    quantile(mids[inds], fweights(counts[inds]), p)
end

#-----------------------------------------------------------------------# FixedBins
mutable struct FixedBins{closed,E<:AbstractVector} <: HistAlg{0}
    edges::E
    counts::Vector{Int}
    out::Int

    function FixedBins{closed,E}(edges::E, counts::Vector{Int},
                                 out::Int) where {E<:AbstractVector,closed}
        closed == :left || closed == :right ||
            error("closed must be left or right")
        length(edges) == length(counts) + 1 ||
            error("Histogram edge vectors must be 1 longer than corresponding count vectors")
        issorted(edges) || error("Histogram edge vectors must be sorted in ascending order")
        new{closed,E}(edges, counts, out)
    end
end
Base.@pure FixedBins(edges::AbstractVector, counts::Vector{Int}, out::Int; closed::Symbol = :left) =
    FixedBins{closed,typeof(edges)}(edges, counts, out)

get_hist_alg(e::AbstractVector; kwargs...) = FixedBins(e, zeros(Int, length(e) - 1), 0; kwargs...)
_midpoints(o::FixedBins) = _midpoints(o.edges)
_counts(o::FixedBins) = o.counts
nobs(o::FixedBins) = sum(o.counts) + o.out
function fit!(o::FixedBins, y, γ::Number)
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
        if isa(edges, Range)
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
        if isa(edges, Range)
            return ceil(Int, (y - a) / step(edges))
        else
            return searchsortedfirst(edges, y) - 1
        end
    end
end

function Base.merge!(o::FixedBins, o2::FixedBins, γ::Number) 
    if o.edges == o2.edges 
        o.counts .+= o2.counts
    else
        for (yi, wi) in zip(_midpoints(o2), o2.counts)
            for k in 1:wi 
                fit!(o, yi, .5)
            end
        end
    end
end

# No linear interpolation (in contrast to AdaptiveBins)
function _pdf(o::FixedBins, y::Real)
    binidx = _binindex(o, y)
    c = o.counts
    if binidx < 1 || binidx > length(c)
        return 0.0
    else
        e = o.edges
        if isa(e, Range)
            area = step(e) * sum(c)
        else
            area = sum((e[i+1] - e[i]) * c[i] for i in 1:length(c))
        end
        return c[binidx] / area
    end
end

#-----------------------------------------------------------------------# AdaptiveBins
# http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf
"""
Calculate a histogram adaptively.

Ref: [http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf](http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf)
"""
struct AdaptiveBins{T} <: HistAlg{0} 
    value::Vector{Pair{T, Int}}
    b::Int
end
get_hist_alg(b::Int) = AdaptiveBins(Pair{Float64, Int}[], b)
get_hist_alg(T::Type, b::Int) = AdaptiveBins(Pair{T, Int}[], b)
_midpoints(o::AdaptiveBins) = first.(o.value)
_counts(o::AdaptiveBins) = last.(o.value)
nobs(o::AdaptiveBins) = sum(last, o.value)

fit!(o::AdaptiveBins, y::Number, γ::Float64) = fit!(o, Pair(y, 1))

function fit!(o::AdaptiveBins, y::Pair{<:Any, Int}) 
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

Base.merge!(o::T, o2::T, γ::Float64) where {T <: AdaptiveBins} = fit!.(o, o2.value)

Base.merge(o::T, o2::T) where {T<:AdaptiveBins} = (o3 = deepcopy(o); fit!.(o3, o2.value); o3)


# based on linear interpolation
function _pdf(o::AdaptiveBins, y::Number)
    v = o.value
    if y ≤ first(first(v)) || y ≥ first(last(v))
        return 0.0
    else 
        i = searchsortedfirst(v, Pair(y, 0)) 
        i == 1 && error("wha")
        q1, k1 = v[i-1]
        q2, k2 = v[i]
        area = sum((first(v[i+1]) - first(v[i])) * (last(v[i]) + last(v[i+1]))/2 for i in 1:length(v)-1)
        return smooth(k1, k2, (y - q1) / (q2 - q1)) / area
    end
end



# Counts in left and right if split at point x
function splitcounts(o::AdaptiveBins, x)
    i = searchsortedfirst(o.value, Pair(x, 1))
    sum(last, o.value[1:(i-1)]), sum(last, o.value[i:end])
end

# Split a histogram in two.  Original = left, new = right.
function split_at!(o::AdaptiveBins{T}, x) where {T}
    k = searchsortedfirst(o.value, Pair(x, 1))
    out = o.value[k:end]
    deleteat!(o.value, k:length(o.value))
    Hist(AdaptiveBins(out, o.b))
end


# Algorithm 3: Sum Procedure
# Estimated number of points in interval [-∞, b]
# b must be inside endpoints
function Base.sum(o::AdaptiveBins, b::Real)
    if !(first(o.value[1]) < b < first(o.value[end]))
        @show first(o.value[1]) < b
        @show b < first(o.value[end])
        error("$b isn't between endpoints")
    end
    # find i such that p(i) ≤ b < p(i+1)
    i = searchsortedfirst(o.value, Pair(b, 1)) - 1
    p1, m1 = o.value[i]
    p2, m2 = o.value[i + 1]
    mb = m1 + (m2 - m1) * (b - p1) / (p2 - p1)
    s = .5 * (m1 + mb) * (b - p1) / (p2 - p1)
    return s + sum(last.(o.value[1:(i-1)])) + m1 / 2
end

# # Algorithm 4: Uniform Procedure (locations of candidate splits)
# function split_candidates(o::AdaptiveBins, B::Integer)
#     # m = nobs(o) / B
#     # cs = cumsum(last.(o.value))
#     # u = Vector{Float64}(B-1)
#     # for j in 2:(B-2)
#     #     s = j * m
#     #     i = searchsortedfirst(cs, s) - 1
#     #     d = s - cs[i]
#     #     p1, m1 = o.value[i]
#     #     p2, m2 = o.value[i + 1]
#     #     a = m2 - m1
#     #     b = 2m1
#     #     c = -2d
#     #     z = a != 0 ? (-b + sqrt(b^2 - 4*a*c)) / (2a) : -c/b
#     #     u[j] = p1 + (p2 - p1) * z
#     # end
#     # u
#     midpoints(first.(o.value))
# end
