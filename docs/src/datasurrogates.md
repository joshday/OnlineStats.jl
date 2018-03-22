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



## Linear Regressions

The [`LinRegBuilder`](@ref) type allows you to fit any linear regression model where `y`
can be any variable and the `x`'s can be any subset of variables.

```@example setup
# make some data
x = randn(10^6, 10)
y = x * linspace(-1, 1, 10) + randn(10^6)

o = fit!(LinRegBuilder(11), [x y])

# adds intercept term by default as last coefficient
coef(o; y = 11, verbose = true)
```

## Histograms

The [`Hist`](@ref) type for online histograms uses a different algorithm based on whether
the argument to the constructor is the number of bins or the bin edges.  `Hist` can be used 
to calculate approximate summary statistics, without the need to revisit the actual data.

```@example setup
o = Hist(20)        # adaptively find bins
o2 = Hist(0:.5:5)  # specify the bin edges
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

