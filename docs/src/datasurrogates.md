```@setup setup
Pkg.add("Plots")
Pkg.add("GR")
using OnlineStats
using Plots
srand(123)
gr()
```

# Data Surrogates

Some `OnlineStat`s are especially useful for out-of-core computations.  After they've been fit, they act as a data stand-in to get summaries, quantiles, regressions, etc, without the need to revisit the entire dataset again.

## Data Summary

See [`Partition`](@ref)

```@example setup
using OnlineStats, Plots

y = rand(["a", "b", "c", "d"], 10^6)

o = Partition(CountMap(String))

s = Series(y, o)

plot(s)
savefig("partition.png"); nothing # hide
```

![](partition.png)

## Linear Regressions

See [`LinRegBuilder`](@ref)

## Histograms

The [`Hist`](@ref) type for online histograms has a 
[Plots.jl](https://github.com/JuliaPlots/Plots.jl) recipe and can also be used to calculate 
approximate summary statistics, without the need to revisit the actual data.

```@example setup
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
savefig("hist.png"); nothing # hide
```

![](hist.png)

