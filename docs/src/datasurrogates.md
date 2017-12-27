# Data Surrogates

Some `OnlineStat`s are especially useful for out-of-core computations.  After they've been fit, they act as a data stand-in to get summaries, quantiles, regressions, etc, without the need to revisit the entire dataset again.

## Data Summary

See [`Partition`](@ref)

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

![](https://user-images.githubusercontent.com/8075494/32749535-aae54900-c88d-11e7-8998-7fa6881635d5.png)

