# http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf

"""
    IHistogram(b::Integer)

Incrementally construct a histogram of `b` bins.

# Example

    using Plots
    o = IHistogram(1000)
    Series(randexp(100_000), o)
    plot(o)
"""
struct IHistogram <: OnlineStat{0, EqualWeight}
    value::Vector{Pair{Float64, Int}}
    buffer::Vector{Float64}
end

IHistogram(b::Integer) = IHistogram(fill(Pair(0.0, 0), b+1), zeros(b))

value(o::IHistogram) = sort!(o.value)

function bin_merge(p1::Pair, p2::Pair)
    k1 = last(p1)
    k2 = last(p2)
    q1 = first(p1)
    q2 = first(p2)
    bottom = k1 + k2
    if bottom == 0 
        return Pair(.5 * (q1 + q2), 0)
    else
        top = (q1 * k1 + q2 * k2)
        return Pair(top / bottom, bottom)
    end
end

fit!(o::IHistogram, y::Real, γ::Float64) = push!(o, Pair(y, 1))

# Idea: make (b + 1) bins and then merge the 2 closest bins
function Base.push!(o::IHistogram, p::Pair)
    v = o.value
    v[end] = p
    sort!(v; alg = InsertionSort)
    for i in eachindex(o.buffer)
        @inbounds o.buffer[i] = first(v[i+1]) - first(v[i])
    end
    _, ind = findmin(o.buffer)
    @inbounds v[ind] = bin_merge(v[ind], v[ind + 1])
    @inbounds v[ind + 1] = v[end]
    @inbounds v[end] = Pair(first(v[end]), 0)
end
