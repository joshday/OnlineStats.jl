# Data Surrogates

Some `OnlineStat`s are especially useful for out-of-core computations.  After they've been fit, they act as a data stand-in to get summaries, quantiles, regressions, etc, without the need to revisit the entire dataset again.

## Data Summary

See [`Partition`](@ref)

```@eval bac
using OnlineStats, Plots

y = rand(["a", "b", "c", "d"], 10^6)

o = Partition(CountMap(String))

s = Series(y, o)

plot(s)

savefig("partition.png")  # hide
nothing
```
![](partition.png)

## Linear Regressions

See [`LinRegBuilder`](@ref)

## Histograms

The [`Hist`](@ref) type for online histograms has a 
[Plots.jl](https://github.com/JuliaPlots/Plots.jl) recipe and can also be used to calculate 
approximate summary statistics, without the need to revisit the actual data.

```julia
o = Hist(100)
s = Series(o)

fit!(s, randexp(100_000))

quantile(o, .5)
quantile(o, [.2, .8])
mean(o)
var(o)
std(o)

using Plots
plot(o)
```

![](https://user-images.githubusercontent.com/8075494/34454746-912a298a-ed37-11e7-8fdd-e2a3fb9048ae.png)
