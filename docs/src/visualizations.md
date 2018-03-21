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

## Many Stats Can Be Plotted

```@example setup
s = fit!(Series(Hist(25), Hist(-5:5)), randn(10^6))
plot(s)
savefig("plot_series.png"); nothing # hide
```

![](plot_series.png)

<!-- ## Naive Bayes Classifier

The [`NBClassifier`](@ref) type stores conditional histograms of the predictor variables, allowing you to plot approximate "group by" distributions:

```@example setup 
# make data
x = randn(10^5, 5)
y = x * [1,3,5,7,9] .> 0

o = NBClassifier(5, Bool)  # 5 predictors with Boolean categories
series((x,y), o)
plot(o)
savefig("nbclassifier.png"); nothing # hide
```
![](nbclassifier.png) -->

<!-- ## Mosaic Plots

The [`Mosaic`](@ref) type allows you to plot the relationship between two categorical variables.  
It is typically more useful than a bar plot, as class probabilities are given by the horizontal
widths.

```@example setup 
x = rand([true, true, false], 10^5)
y = map(xi -> xi ? rand(1:3) : rand(1:4), x)
s = series([x y], Mosaic(Bool, Int))
plot(s)
savefig("mosaic.png"); nothing # hide
```
![](mosaic.png) -->

<!-- ## Partitions

The [`Partition`](@ref) type summarizes sections of a data stream using any `OnlineStat`, 
and is therefore extremely useful in visualizing huge datasets, as summaries are plotted
rather than every single observation.  

#### Continuous Data

```@example setup
y = cumsum(randn(10^6)) + 100randn(10^6)

o = Partition(Hist(50))

s = Series(y, o)

plot(s, xlab = "Nobs")
savefig("partition_hist.png"); nothing # hide
```
![](partition_hist.png)


```@example setup
o = Partition(Mean())
o2 = Partition(Extrema())

s = Series(y, o, o2)

plot(s, layout = 1, xlab = "Nobs")
savefig("partition_mean_ex.png"); nothing # hide
```
![](partition_mean_ex.png)


#### Plot a custom function of the `OnlineStat`s (default is `value`)

Plot of mean +/- standard deviation:

```@example setup
o = Partition(Variance())

s = Series(y, o)

plot(o, x -> [mean(x) - std(x), mean(x), mean(x) + std(x)], xlab = "Nobs")
savefig("partition_ci.png"); nothing # hide  
```
![](partition_ci.png)


#### Categorical Data

```@example setup
y = rand(["a", "a", "b", "c"], 10^6)

o = Partition(CountMap(String), 75)

s = Series(y, o)

plot(o, xlab = "Nobs")
savefig("partition_countmap.png"); nothing # hide
```
![](partition_countmap.png)


## Indexed Partitions

The `Partition` type can only track the number of observations in the x-axis.  If you wish
to plot one variable against another, you can use an `IndexedPartition`.  

```@example setup
x = rand(Date(2000):Date(2020), 10^5)
y = Dates.year.(x) + randn(10^5)

s = Series([x y], IndexedPartition(Date, Hist(20)))

plot(s, xlab = "Date")
savefig("indexpart1.png"); nothing # hide
```
![](indexpart1.png)


```@example setup
x = randn(10^5)
y = x + randn(10^5)

s = Series([x y], IndexedPartition(Float64, Hist(20)))

plot(s, ylab = "Y", xlab = "X")
savefig("indexpart2.png"); nothing # hide
```
![](indexpart2.png)

```@example setup
x = rand('a':'z', 10^5)
y = Float64.(x) + randn(10^5)

s = Series([x y], IndexedPartition(Char, Extrema()))

plot(s, xlab = "Category")
savefig("indexpart3.png"); nothing # hide
```
![](indexpart3.png)

```@example setup
x = rand(10^5)
y = rand(1:5, 10^5)

s = Series([x y], IndexedPartition(Float64, CountMap(Int)))

plot(s, bar_width = 1, xlab = "X", ylab = "Y")
savefig("indexpart4.png"); nothing # hide
```
![](indexpart4.png) -->