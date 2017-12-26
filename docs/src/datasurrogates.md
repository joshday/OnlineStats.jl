# Data Surrogates

Some OnlineStats are especially useful for out-of-core computations, as after they have run
through the data, they can be used as a surrogate for the entire dataset for calculating
approximate summary statistics or exact linear models.

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

plot(o)
```

![](https://user-images.githubusercontent.com/8075494/32749535-aae54900-c88d-11e7-8998-7fa6881635d5.png)

## Visualizations

The [`Partition`](@ref) type uses an OnlineStat to calculate a summary for each part of a 
partitioned dataset.  Plotting a `Partition` provides a way to visualize arbitrarily large
datasets and check for nonstationarity.

```julia
using OnlineStats, Plots
gr()

s = Series(rand(1:4, 10^5), Partition(CountMap(Int)))
plot(s)
```

![](https://user-images.githubusercontent.com/8075494/34360656-cd7accbe-ea30-11e7-8b47-6a9dfbf16dbd.png)