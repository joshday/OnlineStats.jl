"""
    Heatmap(xedges, yedges; left = true, closed = true)
    Heatmap(itr; left = true, closed = true)

Create a two dimensional histogram with the bin partition created by `xedges` and `yedges`.
When fitting a new observation, the first value will be associated with X, the second with Y.

- If `left`, the bins will be left-closed.
- If `closed`, the bins on the ends will be closed.  See [Hist](@ref).

# Example

    using Plots

    xy = zip(randn(10^6), randn(10^6))
    o = fit!(HeatMap(-5:.1:5, -5:.1:5), xy)
    plot(o)

    xy = zip(1 .+ randn(10^6) ./ 10, randn(10^6))
    o = HeatMap(xy)
    plot(o, aspect_ratio=:equal)
"""
mutable struct HeatMap{EX, EY} <: OnlineStat{TwoThings}
    xedges::EX
    yedges::EY
    counts::Matrix{Int}
    out::Int
    left::Bool
    closed::Bool

    function HeatMap(x::T, y::S; left::Bool=true, closed::Bool=true) where {T<:AbstractVector,S<:AbstractVector}
        new{T,S}(x,y, zeros(Int, length(x)-1, length(y)-1), 0, left, closed)
    end
end
function HeatMap(itr, bins::Integer=200; kw...)
    xa, xb = extrema(first, itr)
    ya, yb = extrema(last, itr)
    fit!(HeatMap(range(xa, xb, length=bins), range(ya, yb, length=bins); kw...), itr)
end
nobs(o::HeatMap) = sum(o.counts) + o.out
value(o::HeatMap) = (x=o.xedges, y=o.yedges, z=o.counts)

function _fit!(o::HeatMap, xy)
    i = binindex(o.xedges, xy[1], o.left, o.closed)
    if 1 ≤ i < length(o.xedges)
        j = binindex(o.yedges, xy[2], o.left, o.closed)
        if 1 ≤ j < length(o.yedges)
            o.counts[i, j] += 1
        else
            o.out += 1
        end
    else
        o.out += 1
    end
end

function _merge!(a::HeatMap, b::HeatMap)
    if (a.xedges == b.xedges) && (a.yedges == b.yedges) && (a.left == b.left) && (a.closed == b.closed)
        a.out += b.out
        a.counts .+= b.counts
    else
        @warn "HeatMaps differ in edges or direction of bins being closed.  No merging occurred."
    end
end

@recipe function f(o::HeatMap; marginals=true)
    link --> :x
    z = Float64.(o.counts)
    z[z .== 0] .= NaN
    @series begin
        s = marginals ? 3 : 1
        subplot --> s
        seriestype --> :heatmap
        legend --> false
        o.xedges, o.yedges, z'
    end
    if marginals 
        layout --> (2, 2)
        @series begin
            subplot --> 2 
            seriestype --> :heatmap 
            gride --> false 
            axis --> false 
            framestyle --> :none
            o.xedges, o.yedges, z'
        end
        @series begin 
            subplot --> 1
            label --> ""
            linewidth --> 0
            line_alpha --> 0
            seriestype --> :bar
            o.xedges, vec(sum(o.counts, dims=1))
        end
        @series begin 
            subplot --> 4
            label --> ""
            linewidth --> 0
            line_alpha --> 0
            orientation --> :h
            seriestype --> :bar
            o.yedges, vec(sum(o.counts, dims=2))
        end
    end
end