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


## Partitions

The [`Partition`](@ref) type summarizes sections of a data stream using any `OnlineStat`, 
and is therefore extremely useful in visualizing huge datasets, as summaries are plotted
rather than every single observation.  

![](https://user-images.githubusercontent.com/8075494/34622053-9a69f9b2-f219-11e7-8ed7-f203a47f64f1.gif)

#### Continuous Data

```@example setup
y = cumsum(randn(10^6)) + 100randn(10^6)

o = Partition(Hist(50))

s = Series(y, o)

plot(s)
savefig("partition_hist.png"); nothing # hide
```
![](partition_hist.png)


```@example setup
o = Partition(Mean())
o2 = Partition(Extrema())

s = Series(y, o, o2)

plot(s, layout=1)
savefig("partition_mean_ex.png"); nothing # hide
```
![](partition_mean_ex.png)


#### Plot a custom function of the `OnlineStat`s (default is `value`)

```@example setup
o = Partition(Variance())

s = Series(y, o)

# μ ± σ
plot(o, x -> [mean(x) - std(x), mean(x), mean(x) + std(x)])

savefig("partition_ci.png"); nothing # hide  
```
![](partition_ci.png)


#### Categorical Data

```@example setup
using OnlineStats, Plots

y = rand(["a", "a", "b", "c"], 10^6)

o = Partition(CountMap(String), 75)

s = Series(y, o)

plot(o)
savefig("partition_countmap.png"); nothing # hide
```
![](partition_countmap.png)
