# Visualizations

## Plotting a Series plots the contained OnlineStats

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