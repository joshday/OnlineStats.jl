"""
    Heatmap(xedges, yedges; left = true, closed = true)

Create a two dimensional histogram with the bin partition created by `xedges` and `yedges`.  
When fitting a new observation, the first value will be associated with X, the second with Y.

- If `left`, the bins will be left-closed.
- If `closed`, the bins on the ends will be closed.  See [Hist](@ref).

# Example 

    o = fit!(HeatMap(-5:.1:5, -5:.1:5), eachrow(randn(10^5, 2)))

    using Plots
    plot(o)
"""
mutable struct HeatMap{EX, EY} <: OnlineStat{XY}
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

@recipe function f(o::HeatMap)
    seriestype --> :heatmap 
    z = Float64.(o.counts)
    z[z .== 0] .= NaN
    midpoints(o.xedges), midpoints(o.yedges), z
end