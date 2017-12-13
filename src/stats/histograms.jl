# TODO: Box 2 in https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf

#-----------------------------------------------------------------------# HistAlg
abstract type HistAlg end 

#-----------------------------------------------------------------------# Hist
"""
    Hist(r::Range)
    Hist(b::Int)

Calculate a histogram over bin edges fixed as `r` or adaptively find the best `b` bins.  
The two options use [`KnownBins`](@ref) and [`AdaptiveBins`](@ref), respectively.  
`KnownBins` is much faster, but requires the range of the data to be known before it is 
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
struct Hist{M <: HistAlg} <: ExactStat{0}
    method::M
end
function Base.show(io::IO, h::Hist)
    print(io, "Hist: $(h.method)")
end

# method must implement value --> Tuple of (edge_midpoints, counts)
value(o::Hist) = value(o.method)

function Base.mean(o::Hist) 
    mids, counts = value(o)
    mean(mids, fweights(counts))
end
function Base.var(o::Hist) 
    mids, counts = value(o)
    var(mids, fweights(counts); corrected=true)
end
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

#-----------------------------------------------------------------------# KnownBins
"""
Calculate a histogram over a fixed range.  
"""
struct KnownBins{R <: Range} <: HistAlg 
    edges::R
    counts::Vector{Int}
end
KnownBins(r::Range) = KnownBins(r, zeros(Int, length(r) - 1))
Base.show(io::IO, o::KnownBins) = print(io, "KnownBins(edges = $(o.edges))")
Hist(r::Range) = Hist(KnownBins(r))
value(o::KnownBins) = (_midpoints(o.edges), o.counts)

function fit!(o::Hist{<:KnownBins}, y::Real, γ::Float64)
    x = o.method.edges 
    a = first(x)
    δ = step(x)
    k = floor(Int, (y - a) / δ) + 1
    if 1 <= k < length(x)
        @inbounds o.method.counts[k] += 1
    end
end
_midpoints(r) = r[1:length(r) - 1] + 0.5 * step(r)
function Base.merge!(o::Hist{T}, o2::Hist{T}, γ::Float64) where {T <: KnownBins}
    if o.method.edges == o2.method.edges 
        o.method.counts .+= o2.method.counts
    else
        for (yi, wi) in zip(_midpoints(o2.method.edges), o2.method.counts)
            for k in 1:wi 
                fit!(o, yi, .5)
            end
        end
    end
end



#-----------------------------------------------------------------------# AdaptiveBins
# http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf
"""
Calculate a histogram adaptively.

Ref: [http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf](http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf)
"""
mutable struct AdaptiveBins <: HistAlg 
    values::Vector{Float64}
    counts::Vector{Int}
    n::Int
    AdaptiveBins(b::Int) = new(fill(Inf, b), zeros(Int, b), 0)
end
Hist(b::Int) = Hist(AdaptiveBins(b))
Base.show(io::IO, o::AdaptiveBins) = print(io, "AdaptiveBins($(length(o.values)))")
value(o::AdaptiveBins) = (o.values, o.counts)

fit!(o::Hist{AdaptiveBins}, y::Real, γ::Float64) = push!(o.method, Pair(y, 1))

function Base.push!(o::AdaptiveBins, p::Pair)
    o.n += 1
    i = searchsortedfirst(o.values, first(p))
    insert!(o.values, i, first(p))
    insert!(o.counts, i, last(p))
    ind = find_min_diff(o)
    binmerge!(o, ind)
end

function binmerge!(o::AdaptiveBins, i)
    k2 = o.counts[i+1]
    if k2 != 0
        k1 = o.counts[i]
        q1 = o.values[i]
        q2 = o.values[i + 1]
        o.values[i] = smooth(q1, q2, k2 / (k1 + k2))
        o.counts[i] += k2
    end
    deleteat!(o.values, i + 1)
    deleteat!(o.counts, i + 1)
end

function find_min_diff(o)
    v = o.values
    o.n < length(v) && return o.n
    ind = 0
    mindiff = Inf
    for i in 1:(length(v) - 1)
        @inbounds diff = v[i + 1] - v[i]
        if diff < mindiff 
            mindiff = diff 
            ind = i
        end
    end
    ind
end

function Base.merge!(o::Hist{AdaptiveBins}, o2::Hist{AdaptiveBins}, γ::Float64)
    for p in Pair.(o2.method.values, o2.method.counts)
        push!(o.method, p)
    end
end


# # Algorithm 3: Sum Procedure
# # Estimated number of points in interval [-∞, b]
# function Base.sum(o::IHistogram, b::Real)
#     i = searchsortedfirst(o.value, b)
#     m1 = o.counts[i]
#     m2 = o.counts[i + 1]
#     p1 = o.value[i]
#     p2 = o.value[i + 1]
#     mb = m1 + (m2 - m1) * (b - p1) / (p2 - p1)
#     s = .5 * (m1 + mb) * (b - p1) / (p2 - p1)
#     return s + sum(o.counts[1:(i-1)]) + m1 / 2
# end

# # Algorithm 4: Uniform Procedure (locations of candidate splits)
# function uniform(o::IHistogram, B::Integer)
#     m = sum(o.counts) / B
#     cs = cumsum(o.counts)
#     u = Vector{Float64}(B-1)
#     for j in 1:(B-1)
#         s = j * m
#         i = searchsortedfirst(cs, s)
#         d = s - cs[i]
#         m1 = o.counts[i]
#         m2 = o.counts[i + 1]
#         p1 = o.value[i]
#         p2 = o.value[i + 1]
#         a = m2 - m1
#         b = 2m1
#         c = -2d
#         z = (-b + sqrt(b^2 - 4*a*c)) / (2a)
#         u[j] = p1 + (p2 - p1) * z
#     end
#     u
# end

# #-----------------------------------------------------------------------# summaries
# Base.extrema(o::IHistogram) = (first(o.value), last(o.value))
# Base.mean(o::IHistogram) = mean(o.value, fweights(o.counts))
# Base.var(o::IHistogram) = var(o.value, fweights(o.counts); corrected=true)
# Base.std(o::IHistogram) = sqrt(var(o))
# function Base.quantile(o::IHistogram, p = [0, .25, .5, .75, 1]) 
#     inds = find(o.counts)  # filter out zero weight bins
#     quantile(o.value[inds], fweights(o.counts[inds]), p)
# end
# Base.median(o::IHistogram) = quantile(o, .5)

# function discretized_pdf(o::IHistogram, y::Real)
#     i = searchsortedfirst(o.value, y)
#     if i > length(o.counts)
#         i -= 1
#     end
#     o.counts[i] / sum(o.counts)
# end

# #-----------------------------------------------------------------------# OHistogram
# """
#     OHistogram(range)

# Make a histogram with bins given by `range`.  Uses left-closed bins.  `OHistogram` fits
# faster than [`IHistogram`](@ref), but has the disadvantage of requiring specification of
# bins before data is observed.

# # Example

#     y = randn(100)
#     o = OHistogram(-5:.01:5)
#     s = Series(y, o)
    
#     value(o)  # return StatsBase.Histogram
#     quantile(o)
#     mean(o)
#     var(o)
#     std(o)
# """
# struct OHistogram{H <: Histogram} <: ExactStat{0}
#     h::H
# end
# OHistogram(r::Range) = OHistogram(Histogram(r, :left))
# function fit!(o::OHistogram, y::ScalarOb, γ::Float64)
#     H = o.h
#     x = H.edges[1]
#     a = first(x)
#     δ = step(x)
#     k = floor(Int, (y - a) / δ) + 1
#     if 1 <= k <= length(x)
#         @inbounds H.weights[k] += 1
#     end
# end
# Base.merge!(o::T, o2::T, γ::Float64) where {T <: OHistogram} = merge!(o.h, o2.h)

# _x(o::OHistogram) = (o.h.edges[1] + .5*step(o.h.edges[1]))[2:end]

# Base.mean(o::OHistogram) = mean(_x(o), fweights(o.h.weights))
# Base.var(o::OHistogram) = var(_x(o), fweights(o.h.weights); corrected=true)
# Base.std(o::OHistogram) = sqrt(var(o))

# function Base.quantile(o::OHistogram, p = [0, .25, .5, .75, 1]) 
#     inds = find(o.h.weights)  # filter out zero weights
#     quantile(_x(o)[inds], fweights(o.h.weights[inds]), p)
# end

# #-----------------------------------------------------------------------# 
# mutable struct NextHist{T <: Range} <: ExactStat{0}
#     value::Vector{Int}
#     x::T 
#     n::Int
# end
# NextHist(b::Integer) = NextHist(zeros(Int, b), linspace(0, 0, b), 0)

# function Base.show(io::IO, o::NextHist)
#     print(io, "NextHist(x = $(o.x))")
# end

# function fit!(o::NextHist, y::Real, γ::Float64)
#     x = o.x
#     o.n += 1
#     if o.n == 1
#         o.x = linspace(y, y, length(x))
#     end
#     a, b = extrema(x)
#     if y < a
#         o.x = linspace(y, b, length(x))
#         o.value[1] += 1
#     elseif y > b
#         o.x = linspace(a, y, length(x))
#         o.value[end] += 1
#     elseif o.n > 1
#         if o.n > 1
#             δ = step(x)
#             k = floor(Int, (y - a) / δ) + 1
#             if 1 <= k <= length(x)
#                 @inbounds o.value[k] += 1
#             end
#         end
#     end
# end

#-----------------------------------------------------------------------# deprecations
@deprecate OHistogram(r::Range) Hist(r::Range)
@deprecate IHistogram(b::Int)   Hist(b::Int)