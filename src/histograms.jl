# http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf
"""
    IHistogram(b)

Incrementally build a histogram of `b` (not equally spaced) bins.  

# Example

    o = IHistogram(50)
    Series(randn(1000), o)
"""
struct IHistogram <: OnlineStat{0, EqualWeight}
    value::Vector{Float64}
    counts::Vector{Int}
    buffer::Vector{Float64}
end
IHistogram(b::Integer) = IHistogram(fill(Inf, b), zeros(Int, b), zeros(b))


fit!(o::IHistogram, y::Real, γ::Float64) = push!(o, Pair(y, 1))

function Base.push!(o::IHistogram, p::Pair)
    i = searchsortedfirst(o.value, first(p))
    insert!(o.value, i, first(p))
    insert!(o.counts, i, last(p))
    ind = find_min_diff(o)
    binmerge!(o, ind)
end

function binmerge!(o::IHistogram, i)
    k1 = o.counts[i]
    k2 = o.counts[i + 1] 
    q1 = o.value[i]
    q2 = o.value[i + 1]
    bottom = k1 + k2
    if bottom == 0
        o.value[i] = .5 * (o.value[i] + o.value[i + 1])
    elseif k2 == 0
        top = q1 * k1
        o.value[i] = top / bottom 
        o.counts[i] = bottom
    else
        top = (q1 * k1 + q2 * k2)
        o.value[i] = top / bottom 
        o.counts[i] = bottom
    end
    deleteat!(o.value, i + 1)
    deleteat!(o.counts, i + 1)
end

function find_min_diff(o::IHistogram)
    # find the index of the smallest difference v[i+1] - v[i]
    v = o.value
    @inbounds for i in eachindex(o.buffer)
        val = v[i + 1] - v[i]
        if isnan(val) || isinf(val)
            # If the difference is NaN = Inf - Inf or -Inf = Float64 - Inf
            # merge them to make way for actual values
            return i
        end
        o.buffer[i] = val
    end
    _, ind = findmin(o.buffer)
    return ind
end

function Base.merge!(o::IHistogram, o2::IHistogram, γ::Float64)
    for p in Pair.(o2.value, o2.counts)
        push!(o, p)
    end
end

#-----------------------------------------------------------------------# summaries
Base.extrema(o::IHistogram) = (first(o.value), last(o.value))
Base.mean(o::IHistogram) = mean(o.value, fweights(o.counts))
Base.var(o::IHistogram) = var(o.value, fweights(o.counts); corrected=true)
Base.std(o::IHistogram) = sqrt(var(o))
function Base.quantile(o::IHistogram, p = [0, .25, .5, .75, 1]) 
    inds = find(o.counts)  # filter out zero weight bins
    quantile(o.value[inds], fweights(o.counts[inds]), p)
end
Base.median(o::IHistogram) = quantile(o, .5)