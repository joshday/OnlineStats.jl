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


# function discretized_pdf(o::IHistogram, y::Real)
#     i = searchsortedfirst(o.value, y)
#     if i > length(o.counts)
#         i -= 1
#     end
#     o.counts[i] / sum(o.counts)
# end


#-----------------------------------------------------------------------# deprecations
@deprecate OHistogram(r::Range) Hist(r::Range)
@deprecate IHistogram(b::Int)   Hist(b::Int)