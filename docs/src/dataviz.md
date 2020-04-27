```@setup setup
import Pkg, Random
using Dates
Pkg.add("GR")
Pkg.add("Plots")
ENV["GKSwstype"] = "100"
using OnlineStats
using Plots
using PlotThemes
Random.seed!(1234)
gr()
theme(:bright)
```

# Data Viz

!!! note
    Each of the following examples are plotting one million data points.

## Partitions

The [`Partition`](@ref) type summarizes sections of a data stream using any `OnlineStat`,
and is therefore extremely useful in visualizing huge datasets, as summaries are plotted
rather than every single observation.

#### Continuous Data

```@example setup
y = cumsum(randn(10^6)) + 100randn(10^6)

o = Partition(KHist(10))

fit!(o, y)

plot(o, xlab = "Nobs")
savefig("partition_hist.png"); nothing # hide
```
![](partition_hist.png)


```@example setup
o = Partition(Series(Mean(), Extrema()))

fit!(o, y)

plot(o)
savefig("partition_mean_ex.png"); nothing # hide
```
![](partition_mean_ex.png)


#### Categorical Data

```@example setup
y = rand(["a", "a", "b", "c"], 10^6)

o = Partition(CountMap(String), 75)

fit!(o, y)

plot(o, xlab = "Nobs")
savefig("partition_countmap.png"); nothing # hide
```
![](partition_countmap.png)


## Indexed Partitions

The `Partition` type can only track the number of observations in the x-axis.  If you wish
to plot one variable against another, you can use an `IndexedPartition`.


```@example setup
x = randn(10^6)
y = x + randn(10^6)

o = fit!(IndexedPartition(Float64, KHist(40), 40), zip(x, y))

plot(o)
savefig("indexpart2.png"); nothing # hide
```
![](indexpart2.png)


```@example setup
x = rand(10^6)
y = rand(1:5, 10^6)

o = fit!(IndexedPartition(Float64, CountMap(Int)), zip(x,y))

plot(o, xlab = "X", ylab = "Y")
savefig("indexpart4.png"); nothing # hide
```
![](indexpart4.png)

```@example setup
x = rand(1:1000, 10^6)
y = x .+ 30randn(10^6)

o = fit!(IndexedPartition(Int, KHist(20)), zip(x,y))

plot(o)
savefig("indexpartequal.png"); nothing # hide

```
![](indexpartequal.png)


## Histograms

```@example setup
s = fit!(Series(KHist(25), Hist(-5:.2:5)), randn(10^6))
plot(s)
savefig("plot_series.png") # hide
```

![](plot_series.png)

## Approximate CDF

```@example setup 
o = fit!(OrderStats(1000), randn(10^6))

plot(o)
```

## Mosaic Plots

The [`Mosaic`](@ref) type allows you to plot the relationship between two categorical variables.
It is typically more useful than a bar plot, as class probabilities are given by the horizontal
widths.

```@example setup
using RDatasets 
t = dataset("datasets", "Titanic")

o = Mosaic(String, String)
for (age, surv, n) in zip(t.Age, t.Survived, t.Freq)
    for i in 1:n
        fit!(o, (age, surv))
    end
end

plot(o, legendtitle="Survived", xlabel="Age")
savefig("mosaic.png"); nothing # hide
```
![](mosaic.png)

## HeatMap

```@example setup
o = HeatMap(-5:.1:5, -5:.1:5)

x, y = randn(10^6), randn(10^6)

fit!(o, zip(x, y))

plot(o)
savefig("heatmap.png"); nothing # hide
```
![](heatmap.png)


```@example setup
x, y = randn(10^6), randn(10^6)

o = HeatMap(zip(x, y))

plot(o, aspect_ratio=:equal)
savefig("heatmap2.png"); nothing # hide
```
![](heatmap2.png)

## Naive Bayes Classifier

The [`NBClassifier`](@ref) type stores conditional histograms of the predictor variables, allowing you to plot approximate "group by" distributions:

```@example setup
# make data
x = randn(10^6, 5)
y = x * [1,3,5,7,9] .> 0

o = NBClassifier(5, Bool)  # 5 predictors with Boolean categories
fit!(o, zip(eachrow(x), y))
plot(o)
savefig("nbclassifier.png"); nothing # hide
```
![](nbclassifier.png)

