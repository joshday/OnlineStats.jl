"""
    Mosaic(T::Type, S::Type)

Data structure for generating a mosaic plot, a comparison between two categorical variables.

# Example

```julia
using OnlineStats, Plots
x = [rand() > .8 for i in 1:10^5]
y = rand([1,2,2,3,3,3], 10^5)
o = fit!(Mosaic(Bool, Int), zip(x, y))
plot(o)
```
"""
struct Mosaic{T <: CountMap} <: OnlineStat{TwoThings}
    cm::T
end
Mosaic(T::Type, S::Type) = Mosaic(CountMap{Tuple{T,S}}())
value(o::Mosaic) = value(o.cm)
nobs(o::Mosaic) = nobs(o.cm)
_fit!(o::Mosaic, xy) = fit!(o.cm, Tuple(xy))
_merge!(a::Mosaic, b::Mosaic) = merge!(a.cm, b.cm)

function add_zero_counts!(o::Mosaic)
    v = value(o)
    akeys = [k[1] for k in keys(v)]
    bkeys = [k[2] for k in keys(v)]
    for ai in akeys, bi in bkeys
        get!(v, (ai, bi), 0)
    end
    sort!(v)
    o
end

function split_countmaps(o::Mosaic)
    v = value(o)
    akeys, bkeys = unique(first.(keys(v))), unique(last.(keys(v)))
    a = OrderedDict(k => sum(last, filter(x -> x[1][1] == k, v)) for k in akeys)
    b = OrderedDict(k => sum(last, filter(x -> x[1][2] == k, v)) for k in bkeys)
    sort!(a), sort!(b)
end

@recipe function f(o::Mosaic)
    n = nobs(o)
    a, b = split_countmaps(o)
    d = value(add_zero_counts!(o))

    x = vcat(0.0, cumsum([av / n for av in values(a)]))

    seriestype := :bar
    bar_width := diff(x)
    ylims --> (0,1)
    xlims --> (0, 1)
    label --> permutedims(string.(collect(keys(b))))
    xticks --> (midpoints(x), string.(collect(keys(a))))
    linewidth --> 0.5

    y = reverse(cumsum([d[(av,bv)] / a[av] for av in keys(a), bv in keys(b)], dims=2), dims=2)
    midpoints(x), y
end
