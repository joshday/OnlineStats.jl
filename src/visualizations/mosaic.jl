"""
    Mosaic(T::Type, S::Type)

Data structure for generating a mosaic plot, a comparison between two categorical variables.

# Example

    using OnlineStats, Plots 
    x = [rand() > .8 for i in 1:10^5]
    y = rand([1,2,2,3,3,3], 10^5)
    s = series([x y], Mosaic(Bool, Int))
    plot(s)
"""
struct Mosaic{T, S} <: ExactStat{1}
    value::Dict{T, CountMap{S}}
end
Mosaic(T, S) = Mosaic(Dict{T,CountMap{S}}())
Base.show(io::IO, o::Mosaic{T,S}) where {T, S} = print(io, "Mosaic: $T × $S")
function fit!(o::Mosaic{T, S}, xy, γ) where {T, S}
    x, y = xy
    if haskey(o.value, x)
        fit!(o.value[x], y, 1.0)
    else 
        stat = CountMap(S)
        fit!(stat, y, 1.0)
        o.value[x] = stat
    end
end
nobs(o::Mosaic) = sum(nobs, values(o.value))
Base.keys(o::Mosaic) = sort!(collect(keys(o.value)))
subkeys(o::Mosaic) = sort!(mapreduce(x->collect(keys(x)), union, values(o.value)))


@recipe function f(o::Mosaic{T,S}) where {T,S}
    kys = sort!(collect(keys(o.value)))
    n = nobs(o)
    xwidths = [nobs(o.value[ky]) / n for ky in kys]
    xedges = vcat(0.0, cumsum(xwidths))

    subkys = subkeys(o)
    y = zeros(length(subkys), length(kys))
    for (j, ky) in enumerate(kys) 
        y[:, j] = probs(o.value[ky], subkys)
        y[:, j] = 1.0 - vcat(0.0, cumsum(y[1:(end-1), j]))
    end

    seriestype := :bar
    bar_widths := xwidths
    labels := subkys
    xticks := (midpoints(xedges), kys)
    xlim := (0, 1)
    ylim := (0, 1)

    xedges, y'
end