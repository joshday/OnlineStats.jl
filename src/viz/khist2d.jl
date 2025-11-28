#-----------------------------------------------------------------------# Bin2D
mutable struct Bin2D
    x::Float64
    y::Float64
    z::Int
end
distance(a::Bin2D, b::Bin2D) = sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
function _merge!(a::Bin2D, b::Bin2D)
    γ = b.z / (a.z += b.z)
    a.x = smooth(a.x, b.x, γ)
    a.y = smooth(a.y, b.y, γ)
end
nobs(o::Bin2D) = o.z

#-----------------------------------------------------------------------# KHist2D
"""
    KHist2D(b=300)

Approximate scatterplot of `b` centers.  This implementation is slow!  See [`IndexedPartition`](@ref)
and [`KIndexedPartition`](@ref) instead.

# Example

```julia
x = randn(10^4)
y = x + randn(10^4)
plot(fit!(KHist2D(), zip(x, y)))
```
"""
struct KHist2D <: OnlineStat{TwoThings{<:Number, <:Number}}
    value::Vector{Bin2D}
    b::Int
end
KHist2D(b::Int=300) = KHist2D(Bin2D[], b)

nobs(o::KHist2D) = length(o.value) > 0 ? sum(nobs, o.value) : 0

# Works, but much room to optimize
function _fit!(o::KHist2D, xy)
    newbin = Bin2D(xy..., 1)
    push!(o.value, newbin)
    if length(o.value) > o.b
        i, j = 1, 2
        mindist = Inf
        for _i in 1:o.b
            v1 = o.value[_i]
            for _j in (_i + 1):o.b
                dist = distance(v1, o.value[_j])
                if dist < mindist
                    mindist = dist
                    i = _i
                    j = _j
                end
            end
        end
        _merge!(o.value[i], o.value[j])
        deleteat!(o.value, j)
    end
end

@recipe function f(o::KHist2D; maxsize=10, minsize=1)
    x = [v.x for v in o.value]
    y = [v.y for v in o.value]
    z = [v.z for v in o.value]
    marker_z --> z
    markersize --> z / maximum(nobs, o.value) .* maxsize .+ minsize
    markerstrokewidth --> 0
    seriestype --> :scatter
    seriescolor --> :viridis
    x, y
end
