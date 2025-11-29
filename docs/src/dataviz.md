```@setup setup
import Random
using Dates
using OnlineStats
using Plots
gr(size=(816,400), margin=6Plots.mm)
Random.seed!(1234)
```

# Data Visualization

!!! note
    Each of the following examples plots one million data points, but can scale to infinitely many
    observations, since only a summary (`OnlineStat`) of the data is plotted.

## Partitions

The [`Partition`](@ref) type summarizes sections of a data stream using any `OnlineStat`,
and is therefore extremely useful in visualizing huge datasets, as summaries are plotted
rather than every single observation.

#### Continuous Data

```@example setup
y = cumsum(randn(10^6)) + 100randn(10^6)

o = Partition(KHist(10))

fit!(o, y)

plot(o)
```


```@example setup
o = Partition(Series(Mean(), Extrema()))

fit!(o, y)

plot(o)
```


#### Categorical Data

```@example setup
y = rand(["a", "a", "b", "c"], 10^6)

o = Partition(CountMap(String), 75)

fit!(o, y)

plot(o)
```


## Indexed Partitions

The `Partition` type can only track the number of observations in the x-axis.  If you wish
to plot one variable against another, you can use an `IndexedPartition`.


```@example setup
x = randn(10^6)
y = x + randn(10^6)

o = fit!(IndexedPartition(Float64, KHist(40), 40), zip(x, y))

plot(o)
```


```@example setup
x = rand(10^6)
y = rand(1:5, 10^6)

o = fit!(IndexedPartition(Float64, CountMap(Int)), zip(x,y))

plot(o, xlab = "X", ylab = "Y")
```

Due to a limitation with Plots.jl, `Date` and `DateTime` will sometimes be converted to their `Dates.value` when plotted.  To get human-readable tick labels, you can use the `xformatter` keyword argument to `plot`.

```@example setup
using Dates

x = rand(Date(2019):Day(1):Date(2020), 10^6)
y = Dates.value.(x) .+ 30randn(10^6)

o = fit!(IndexedPartition(Date, KHist(20)), zip(x,y))

plot(o, xformatter = x -> string(Date(Dates.UTInstant(Day(x)))))
```

## K-Indexed Partitions

A [`KIndexedPartition`](@ref) is simlar to an [`IndexedPartition`](@ref), but uses a different method
of binning the x variable (centroids vs. intervals), similar to that of [`KHist`](@ref).

For the sake of performance, you must provide a **function** that creates
the OnlineStat you wish to calculate for the y variable.

```@example setup
x = randn(10^6)
y = x + randn(10^6)

o = fit!(KIndexedPartition(Float64, () -> KHist(20)), zip(x, y))

plot(o)
```

## Histograms

```@example setup
s = fit!(Series(KHist(25), Hist(-5:.2:5), ExpandingHist(100)), randn(10^6))
plot(s, link = :x, label = ["KHist" "Hist" "ExpandingHist"])
```

## Average Shifted Histograms (ASH)

ASH is a semi-parametric density estimation method that is similar to Kernel Density Estimation,
but uses a fine partition histogram instead of individual observations to perform the smoothing.

```@example setup
o = fit!(Ash(ExpandingHist(1000), 5), randn(10^6))
plot(o)
```

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
t = dataset("ggplot2", "diamonds")

o = Mosaic(eltype(t.Cut), eltype(t.Color))

fit!(o, zip(t.Cut, t.Color))

plot(o, legendtitle="Color", xlabel="Cut")
```

## HeatMap

```@example setup
o = HeatMap(-5:.1:5, -0:.1:10)

x, y = randn(10^6), 5 .+ randn(10^6)

fit!(o, zip(x, y))

plot(o)
```


```@example setup
plot(o, marginals=false, legend=true)
```


## Traces

A [`Trace`](@ref) will take snapshots of an OnlineStat as it is fitted, allowing you view how the value changed as observations were added.  This can be useful for identifying [concept drift](https://en.wikipedia.org/wiki/Concept_drift) or finding optimal hyperparameters for stochastic approximation methods like [`StatLearn`](@ref).

```@example setup
y = range(1, 20, length=10^6) .* randn(10^6)

o = Trace(Extrema())

fit!(o, y)

plot(o)
```


## Naive Bayes Classifier

The [`NBClassifier`](@ref) type stores conditional histograms of the predictor variables, allowing you to plot approximate "group by" distributions:

```@example setup
# make data
x = randn(10^6, 5)
y = x * [1,3,5,7,9] .> 0

o = NBClassifier(5, Bool)  # 5 predictors with Boolean categories
fit!(o, zip(eachrow(x), y))
plot(o)
```
