```@setup setup
Pkg.add("GR")
Pkg.add("Plots")
ENV["GKSwstype"] = "100"
using OnlineStats
using Plots
srand(1234)
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
`Partition` is therefore extremely useful in visualizing huge datasets, as summaries are plotted
rather than every single observation.  

![](https://user-images.githubusercontent.com/8075494/34622053-9a69f9b2-f219-11e7-8ed7-f203a47f64f1.gif)

### Partition Plotting options

```@example setup
o = Partition(Mean())

s = Series(randn(10^6), o)

plot(o)  

savefig("part1.png"); nothing # hide  
```

![](part1.png)

#### Connect lines for readability

```@example setup
plot(o; connect = true)

savefig("part2.png"); nothing # hide  
```

![](part2.png)

#### Turn off the vertical separators

```@example setup
plot(o; parts = false)

savefig("part3.png"); nothing # hide  
```

![](part3.png)

#### Plot a custom function of the `OnlineStat`s (default is `value`)

```@example setup
plot(o, x -> mean(x) + 100)

savefig("part4.png"); nothing # hide  
```

![](part4.png)

### Examples

#### Special Plot Recipe for `CountMap`

```@example setup
using OnlineStats, Plots

y = rand(["a", "a", "b", "c"], 10^6)

o = Partition(CountMap(String), 75)

s = Series(y, o)

plot(o)
savefig("partition.png"); nothing # hide
```

![](partition.png)

#### If Output is two numbers, it's filled in (`Extrema`)

```@example setup
y = cumsum(randn(10^6))

o = Partition(Mean())
o2 = Partition(Extrema())

s = Series(y, o, o2)

plot(plot(o), plot(o2))
savefig("partition2.png"); nothing # hide
```

![](partition2.png)


#### Special Plot Recipe for `Hist`

```@example setup
y = cumsum(randn(10^6)) + 100randn(10^6)

o = Partition(Hist(50))

s = Series(y, o)

plot(s; legend=false, colorbar=true)
savefig("partition3.png"); nothing # hide
```

![](partition3.png)

#### Plot a custom function (mean ± std)

```@example setup

o = Partition(Variance())

y = randn(10^6) + linspace(0, 1, 10^6)

s = Series(y, o)

plot(o, x -> [mean(x) - std(x), mean(x), mean(x) + std(x)])
savefig("partition4.png"); nothing # hide
```
![](partition4.png)
