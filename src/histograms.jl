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
end

IHistogram(b::Integer) = IHistogram(fill(Pair(0.0, 0), b + 1))

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


function fit!(o::IHistogram, y::ScalarOb, γ::Float64)
    v = o.value
    v[end] = Pair(y, 1)
    sort!(v)
    ind = findmin(diff(first.(v)))[2]
    v[ind] = bin_merge(v[ind], v[ind + 1])
    v[ind + 1] = v[end]
    v[end] = Pair(first(v[end]), 0)
end
