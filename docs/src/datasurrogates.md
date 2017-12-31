```@setup setup
Pkg.add("GR")
Pkg.add("Plots")
ENV["GKSwstype"] = "100"
using OnlineStats
using Plots
srand(123)
gr()
```

# Data Surrogates

Some `OnlineStat`s are especially useful for out-of-core computations.  After they've been fit, they act as a data stand-in to get summaries, quantiles, regressions, etc, without the need to revisit the entire dataset again.

## Summarize Partitioned Data

The [`Partition`](@ref) type summarizes sections of a data stream using any `OnlineStat`. 
`Partition` has a fallback plot recipe that works for most `OnlineStat`s and specific plot
recipes for [`Variance`](@ref) (summarizes with mean and 95% CI) and [`CountMap`](@ref) (see below).

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

## Linear Regressions

The [`LinRegBuilder`](@ref) type allows you to fit any linear regression model where `y`
can be any variable and the `x`'s can be any subset of variables.

```@example setup
# make some data
x = randn(10^6, 10)
y = x * linspace(-1, 1, 10) + randn(10^6)

o = LinRegBuilder(11)

s = Series([x y], o)

# adds intercept term by default as last coefficient
coef(o; y = 11, verbose = true)
```

## Histograms

The [`Hist`](@ref) type for online histograms uses a different algorithm based on whether
the argument to the constructor is the number of bins or the bin edges.  `Hist` can be used 
to calculate approximate summary statistics, without the need to revisit the actual data.

```@example setup
o = Hist(20)        # adaptively find bins
o2 = Hist(-5:.5:5)  # specify the bin edges
s = Series(o, o2)

fit!(s, randexp(100_000))

quantile(o, .5)
quantile(o, [.2, .8])
mean(o)
var(o)
std(o)

using Plots
plot(s)
savefig("hist.png"); nothing # hide
```

![](hist.png)

