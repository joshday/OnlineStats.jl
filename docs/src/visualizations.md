```@setup setup
Pkg.add("GR")
Pkg.add("Plots")
ENV["GKSwstype"] = "100"
using OnlineStats
using Plots
srand(123)
gr()
```

# Visualizations

## Plotting a Series plots the contained OnlineStats

```@example setup
    s = Series(randn(10^6), Hist(25), Hist(-5:5))
    plot(s)
    savefig("plot_series.png"); nothing # hide
```

![](plot_series.png)


!!! note
    Due to the lightweight nature of [RecipesBase](https://github.com/JuliaPlots/RecipesBase.jl), there is occasionally a mix-up of a data series appearing in the wrong subplot.  A workaround is to plot each `OnlineStat` separately, e.g. `plot(plot(o1), plot(o2))` or `plot(plot.(stats(my_series))...)`.

## Partitions

The [`Partition`](@ref) type summarizes sections of a data stream using any `OnlineStat`. 
`Partition` is therefore extremely useful in visualizing huge data, as summaries are plotted
rather than every single observation.

```@example setup
using OnlineStats, Plots

y = rand(["a", "a", "b", "c"], 10^6)

o = Partition(CountMap(String))

s = Series(y, o)

plot(o)
savefig("partition.png"); nothing # hide
```

![](partition.png)

```@example setup
using OnlineStats, Plots

y = cumsum(randn(10^6))

o = Partition(Mean())
o2 = Partition(Extrema())

s = Series(y, o, o2)

plot(plot(o), plot(o2))
savefig("partition2.png"); nothing # hide
```

![](partition2.png)

```@example setup
using OnlineStats, Plots

y = cumsum(randn(10^6))

o = Partition(Hist(50))

s = Series(y, o)

plot(s)
savefig("partition3.png"); nothing # hide
```

![](partition3.png)