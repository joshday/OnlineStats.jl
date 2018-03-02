# TODO: Box 2 in https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf

#-----------------------------------------------------------------------# HistAlg
abstract type HistAlg{N} end 
input(o::HistAlg{N}) where {N} = N
Base.show(io::IO, o::HistAlg) = print(io, name(o, false, false))
get_hist_alg(o::HistAlg) = o

# get_hist_alg(args...)     --> HistAlg 
# _midpoints(o)             --> midpoints of bins 
# _counts(o)                --> counts in bins
# nobs
# fit!
# merge!

_midpoints(r) = r[1:length(r) - 1] + 0.5 * step(r)

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
struct Hist{N, H <: HistAlg} <: ExactStat{N}
    alg::H
end
function Hist(args...)
    alg = get_hist_alg(args...)
    N = input(alg)
    Hist{N, typeof(alg)}(alg)
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

#-----------------------------------------------------------------------# FixedRangeBins
mutable struct FixedRangeBins{R <: Range} <: HistAlg{0} 
    edges::R 
    counts::Vector{Int}
    out::Int
end
get_hist_alg(r::Range) = FixedRangeBins(r, zeros(Int, length(r) - 1), 0)
_midpoints(o::FixedRangeBins) = _midpoints(o.edges)
_counts(o::FixedRangeBins) = o.counts
nobs(o::FixedRangeBins) = sum(o.counts) + o.out
function fit!(o::FixedRangeBins, y, γ::Number)
    r = o.edges 
    a = first(r)
    δ = step(r)
    k = floor(Int, (y-a) / δ) + 1
    if 1 ≤ k < length(r)
        @inbounds o.counts[k] += 1
    else 
        o.out += 1
    end
end
function Base.merge!(o::FixedRangeBins, o2::FixedRangeBins, γ::Number) 
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
function _pdf(o::FixedRangeBins, y::Real)
    e = o.edges
    if y ≤ first(e)
        return 0.0
    elseif y ≥ last(e)
        return 0.0 
    else
        c = o.counts
        i = min(searchsortedfirst(e, y), length(c))
        δ = step(e)
        return c[i] / (δ * sum(c))
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
    first(o.value[1]) < b < first(o.value[end]) || error("$b isn't between endpoints")
    # find i such that p(i) ≤ b < p(i+1)
    i = searchsortedfirst(o.value, Pair(b, 1)) - 1
    p1, m1 = o.value[i]
    p2, m2 = o.value[i + 1]
    mb = m1 + (m2 - m1) * (b - p1) / (p2 - p1)
    s = .5 * (m1 + mb) * (b - p1) / (p2 - p1)
    return s + sum(last.(o.value[1:(i-1)])) + m1 / 2
end

# Algorithm 4: Uniform Procedure (locations of candidate splits)
function split_candidates(o::AdaptiveBins, B::Integer)
    m = nobs(o) / B
    cs = cumsum(last.(o.value))
    u = Vector{Float64}(B-1)
    for j in 1:(B-1)
        s = j * m
        i = searchsortedfirst(cs, s)
        d = s - cs[i]
        p1, m1 = o.value[i]
        p2, m2 = o.value[i + 1]
        a = m2 - m1
        b = 2m1
        c = -2d
        z = (-b + sqrt(b^2 - 4*a*c)) / (2a)
        u[j] = p1 + (p2 - p1) * z
    end
    u
end
