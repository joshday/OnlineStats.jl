"""
    Ash(h::Union{KHist, Hist, ExpandingHist})
    Ash(h::Union{KHist, Hist, ExpandingHist}, m::Int, kernel::Function)

Create an Average Shifted Histogram using `h` as the base histogram with smoothing parameter `m`
and kernel function `kernel`.  Built-in kernels are available in the `OnlineStats.Kernels` module.

# Example

```julia
using OnlineStats, Plots

o = fit!(Ash(ExpandingHist(1000)), randn(10^6))

plot(o)
plot(o, 20)
plot(o, OnlineStats.Kernels.epanechnikov, 4)
```
"""
mutable struct Ash{H, T} <: OnlineStat{Number}
    hist::H
    density::T
    m::Int
    kernel::Function
end

_default_m(h) = ceil(Int, .05 * length(edges(h)))
_default_m(h::KHist) = ceil(Int, .05 * h.k)

_default_density(h) = zeros(length(counts(h)))
_default_density(h::KHist) = zeros(h.k)

Ash(h, kernel::Function, m::Int = _default_m(h)) = Ash(h, m, kernel)

function Ash(h, m::Int = _default_m(h), kernel::Function = Kernels.biweight)
    Ash(h, _default_density(h), m, kernel)
end

_fit!(o::Ash, data) = _fit!(o.hist, data)

nobs(o::Ash) = nobs(o.hist)

value(o::Ash, kernel::Function, m::Int = o.m) = value(o, m, kernel)

function value(o::Ash, m::Int = o.m, kernel::Function = o.kernel)
    if nobs(o) > 0
        o.m = m
        o.kernel = kernel
        y = o.density
        y .= 0.0
        counts = OnlineStats.counts(o.hist)
        b = length(counts)
        mids = midpoints(o.hist)
        for k in eachindex(mids)
            if counts[k] > 0
                for i in max(1, k - m + 1):min(b, k + m - 1)
                    y[i] += counts[k] * kernel((i - k) / m)
                end
            end
        end
        density_sum_to_1!(o)
        inds = findfirst(x -> x > 0, y):findlast(x -> x > 0, y)
        return (x = mids[inds], y = y[inds])
    else
        return (x=midpoints(o.hist), y=o.density)
    end
end

function density_sum_to_1!(o::Ash{<:HistogramStat})
    rmul!(o.density, 1 / (sum(o.density) * step(edges(o.hist))))
end
function density_sum_to_1!(o::Ash{<:KHist})
    o.density ./= area(midpoints(o.hist), o.density)
end

#-----------------------------------------------------------------------------# Plots
histdensity(o::Ash) = counts(o.hist) ./ nobs(o) ./ step(edges(o.hist))
histdensity(o::Ash{<:KHist}) = counts(o.hist) ./ area(o.hist)

@recipe f(o::Ash, kernel::Function, m::Int = o.m) = o, m, kernel

@recipe function f(o::Ash, m::Int = o.m, kernel::Function = o.kernel; hist=true)
    if hist
        @series begin
            normalize --> true
            seriesalpha --> .4
            seriestype --> :sticks
            label --> "Histogram Density"
            midpoints(o.hist), histdensity(o)
        end
    end
    @series begin
        x, y = value(o, m, kernel)
        label --> "Ash(m=$(m), kernel=$(o.kernel))"
        xlims --> extrema(x)
        linewidth --> 3
        x, y
    end
end

#-----------------------------------------------------------------------------# kernels
module Kernels
in_range(u) = abs(u) ≤ 1

biweight(u)         = in_range(u) ? (1.0 - u ^ 2) ^ 2 : 0.0
cosine(u)           = in_range(u) ? cos(0.5 * π * u) : 0.0
epanechnikov(u)     = in_range(u) ? 1.0 - u ^ 2 : 0.0
triangular(u)       = in_range(u) ? 1.0 - abs(u) : 0.0
tricube(u)          = in_range(u) ? (1.0 - abs(u) ^ 3) ^ 3 : 0.0
triweight(u)        = in_range(u) ? (1.0 - u ^ 2) ^ 3 : 0.0
uniform(u)          = in_range(u) ? 0.5 : 0.0

gaussian(u) = exp(-0.5 * u ^ 2)
logistic(u) = 1.0 / (exp(u) + 2.0 + exp(-u))
end
