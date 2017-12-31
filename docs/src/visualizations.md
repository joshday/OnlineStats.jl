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
    s = Series(randn(10^6), Hist(25), Hist(-5:.1:5))
    plot(s)
    savefig("plot_series.png"); nothing # hide
```

![](plot_series.png)


!!! note
    Due to the lightweight nature of [RecipesBase](https://github.com/JuliaPlots/RecipesBase.jl), there is occasionally a mix-up of a data series appearing in the wrong subplot.  A workaround is to plot each `OnlineStat` separately, e.g. `plot(plot(o1), plot(o2))` or `plot(plot.(stats(my_series))...)`.

