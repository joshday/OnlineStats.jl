[![OnlineStats](http://pkg.julialang.org/badges/OnlineStats_0.4.svg)](http://pkg.julialang.org/?pkg=OnlineStats&ver=0.4)
[![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/x2t1ey2sgbmow1a4/branch/master?svg=true)](https://ci.appveyor.com/project/joshday/onlinestats-jl/branch/master)
[![codecov.io](https://codecov.io/github/joshday/OnlineStats.jl/coverage.svg?branch=master)](https://codecov.io/github/joshday/OnlineStats.jl?branch=master)


# OnlineStats

**Online algorithms for statistics.**

**OnlineStats** is a Julia package which provides online algorithms for statistical models.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.


# [API and Examples](doc/api.md)

# Overview
### Every OnlineStat is a Type
```julia
using OnlineStats
o = Mean()
```

### All OnlineStats can be updated
```julia
y = randn(100)
y2 = randn(100)

# update Mean
for yi in y
    fit!(o, yi)
end
for yi in y2
    fit!(o, yi)
end

# or more simply:
fit!(o, y)
fit!(o, y2)
```

### OnlineStats share a common interface
- `value(o)`
    - the associated value of an OnlineStat
- `nobs(o)`
    - the number of observations seen


# What Can OnlineStats Do?
While many estimates can be calculated analytically with an online algorithm, several
type rely on stochastic approximation.

### Summary Statistics
- Mean: `Mean`, `Means`
- Variance: `Variance`, `Variances`
- Quantiles: `QuantileMM`, `QuantileSGD`
- Covariance Matrix: `CovMatrix`
- Maximum and Minimum:  `Extrema`
- Skewness and Kurtosis:  `Moments`
- Sum/Differences:  `Sum`, `Sums`, `Diff`, `Diffs`

### Density Estimation
- `distributionfit(D, data)`
    - For `D in [Beta, Categorical, Cauchy, Gamma, LogNormal, Normal, Multinomial, MvNormal]`
- Gaussian Mixtures: `NormalMix`

### Predictive Modeling
- Linear Regression: `LinReg`, `StatLearn`
- Logistic Regression: `StatLearn`
- Poisson Regression: `StatLearn`
- Support Vector Machines: `StatLearn`
- Quantile Regression: `StatLearn`, `QuantReg`
- Huber Loss Regression: `StatLearn`
- L1 Loss Regression: `StatLearn`

### Experimental Features
- K-Means clustering: `KMeans`
- Bootstrapping: `BernoulliBootstrap`, `PoissonBootstrap`
- Approximate count of distinct elements: `HyperLogLog`
- Visualizing value of OnlineStats: `TracePlot`, `CompareTracePlot`
