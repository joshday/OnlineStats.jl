[![OnlineStats](http://pkg.julialang.org/badges/OnlineStats_0.6.svg)](http://pkg.julialang.org/?pkg=OnlineStats)
[![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/x2t1ey2sgbmow1a4/branch/master?svg=true)](https://ci.appveyor.com/project/joshday/onlinestats-jl/branch/master)
[![codecov](https://codecov.io/gh/joshday/OnlineStats.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/joshday/OnlineStats.jl)



# OnlineStats

**Online algorithms for statistics.**

**OnlineStats** is a Julia package which provides online algorithms for statistical models.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.

---

# Readme Contents

1. [What Can OnlineStats Do?](#what-can-onlinestats-do)
1. [Basics](#basics)
1. [Weighting](#weighting)
1. [Series](#series)
1. [Merging](#merging)
1. [Callbacks](#callbacks)

---


# What Can OnlineStats Do?

| Statistic/Model                        | OnlineStat                                    |
|:---------------------------------------|:----------------------------------------------|
| **Univariate Statistics:**             |                                               |
| mean                                   | [`Mean`](doc/api.md#mean)                     |
| variance                               | [`Variance`](doc/api.md#variance)             |
| quantiles via SGD                      | [`QuantileSGD`](doc/api.md#quantilesgd)       |
| quantiles via Online MM                | [`QuantileMM`](doc/api.md#quantilemm)         |
| max and min                            | [`Extrema`](doc/api.md#extrema)               |
| skewness and kurtosis                  | [`Moments`](doc/api.md#moments)               |
| sum                                    | [`Sum`](doc/api.md#sum)                       |
| difference                             | [`Diff`](doc/api.md#diff)                     |
| **Multivariate Analysis:**             |                                               |
| covariance matrix                      | [`CovMatrix`](doc/api.md#covmatrix)           |
| k-means clustering                     | [`KMeans`](doc/api.md#kmeans)                 |
| multiple univariate statistics         | [`MV{<:OnlineStat}`](doc/api.md#mv)           |
| **Density Estimation:**                |                                               |
| gaussian mixture                       | [`NormalMix`](doc/api.md#normalmix)           |
| Beta                                   | [`FitBeta`](doc/api.md#fitbeta)               |
| Categorical                            | [`FitCategorical`](doc/api.md#fitcategorical) |
| Cauchy                                 | [`FitCauchy`](doc/api.md#fitcauchy)           |
| Gamma                                  | [`FitGamma`](doc/api.md#fitgamma)             |
| LogNormal                              | [`FitLogNormal`](doc/api.md#fitlognormal)     |
| Normal                                 | [`FitNormal`](doc/api.md#fitnormal)           |
| Multinomial                            | [`FitMultinomial`](doc/api.md#fitmultinomial) |
| MvNormal                               | [`FitMvNormal`](doc/api.md#fitmvnormal)       |
| **Statistical Learning:**              |                                               |
| GLMs with regularization               | [`StatLearn`](doc/api.md#statlearn)           |
| Linear regression                      | [`LinReg`](doc/api.md#linreg)                 |
| **Other:**                             |                                               |
| Bootstrapping                          | [`Bootstrap`](doc/api.md#bootstrap)           |
| approximate count of distinct elements | [`HyperLogLog`](doc/api.md$hyperloglog)       |


[go to top](#readme-contents)
# Basics
### Every OnlineStat is a type
```julia
m = Mean()
v = Variance()
```

### OnlineStats are grouped by Series
```julia
s = Series(m, v)
```

### Updating a Series updates the OnlineStats
```julia
y = randn(100)

for yi in y
    fit!(s, yi)
end

# or more simply:
fit!(s, y)
```
[go to top](#readme-contents)
# Weighting

Series are parameterized by a `Weight` type that controls the influence the next observation
has on the OnlineStats contained in the Series.

```julia
s = Series(EqualWeight(), Mean())
```

Consider how weights affect the influence the next observation has on an online mean.  Many OnlineStats have an update which takes this form:

<img width="416" src="https://cloud.githubusercontent.com/assets/8075494/25097527/ec26e70e-2372-11e7-9b3c-6ce3cd40afe4.png">

| Constructor                                              | Weight at Update `t`       |
|:---------------------------------------------------------|:---------------------------|
| [`EqualWeight()`](doc/api.md#equalweight)                | `γ(t) = 1 / t`             |
| [`ExponentialWeight(λ)`](doc/api.md#exponentialweight)   | `γ(t) = λ`                 |
| [`BoundedEqualWeight(λ)`](doc/api.md#boundedequalweight) | `γ(t) = max(1 / t, λ)`     |
| [`LearningRate(r, λ)`](doc/api.md#learningrate)          | `γ(t) = max(1 / t ^ r, λ)` |

![](https://cloud.githubusercontent.com/assets/8075494/18796073/9c844b30-8195-11e6-89a1-7ad9b4d891f2.png)

[go to top](#readme-contents)
# Series

Series are the workhorse of OnlineStats.  A Series tracks
1. The Weight
2. An OnlineStat or tuple of OnlineStats.

### Creating a Series
```julia
Series(Mean())
Series(Mean(), Variance())

Series(ExponentialWeight(), Mean())
Series(ExponentialWeight(), Mean(), Variance())

y = randn(100)

Series(y, Mean())
Series(y, Mean(), Variance())

Series(y, ExponentialWeight(.01), Mean())
Series(y, ExponentialWeight(.01), Mean(), Variance())
```

### Updating a Series
There are multiple ways to update the OnlineStats in a Series
- Single observation
  - Note: A single observation is a vector for OnlineStats such as `CovMatrix`
```julia
s = Series(Mean())
fit!(s, randn())

s = Series(CovMatrix(4))
fit!(s, randn(4))
fit!(s, randn(4))
```
- Single observation, override weight
```julia
s = Series(Mean())
fit!(s, randn(), rand())
```
- Multiple observations
  - Note: multiple observations are a matrix for OnlineStats such as `CovMatrix`.  By default, each *row* is considered an observation.  However, there exists `fit!` methods which use observations in *columns*.
```julia
s = Series(Mean())
fit!(s, randn(100))

s = Series(CovMatrix(4))
fit!(s, randn(100, 4))                 # Observations in rows
fit!(s, randn(4, 100), ObsDim.Last())  # Observations in columns
```

- Multiple observations, use the same weight for all
```julia
s = Series(Mean())
fit!(s, randn(100), .01)
```
- Multiple observations, provide vector of weights
```julia
s = Series(Mean())
fit!(s, randn(100), rand(100))
```
- Multiple observations, update in minibatches  
  OnlineStats which use stochastic approximation (`QuantileSGD`, `QuantileMM`, `KMeans`, etc.) have different behavior if they are updated in minibatches.  

  ```julia
  s = Series(QuantileSGD())
  fit!(s, randn(1000), 7)
  ```

[go to top](#readme-contents)
# Merging

Two Series can be merged if they track the same OnlineStats and those OnlineStats are
mergeable.  The syntax for in-place merging is

```julia
merge!(series1, series2, arg)
```

Where `series1`/`series2` are Series that contain the same OnlineStats and `arg` is used to determine how `series2` should be merged into `series1`.


```julia
using OnlineStats

y1 = randn(100)
y2 = randn(100)

s1 = Series(y1, Mean(), Variance())
s2 = Series(y2, Mean(), Variance())

# Treat s2 as a new batch of data.  Essentially:
# s1 = Series(Mean(), Variance()); fit!(s1, y1); fit!(s1, y2)
merge!(s1, s2, :append)

# Use weighted average based on nobs of each Series
merge!(s1, s2, :mean)

# Treat s2 as a single observation.
merge!(s1, s2, :singleton)

# Provide the ratio of influence s2 should have.
merge!(s1, s2, .5)
```

[go to top](#readme-contents)
# Callbacks

While an OnlineStat is being updated, you may wish to perform an action like print intermediate results to a log file or update a plot.  For this purpose, OnlineStats exports a [`maprows`](doc/api.md#maprows) function.

`maprows(f::Function, b::Integer, data...)`

`maprows` works similar to `Base.mapslices`, but maps `b` rows at a time.  It is best used with Julia's do block syntax.

### Example 1
- Input
```julia
y = randn(100)
s = Series(Mean())
maprows(20, y) do yi
    fit!(s, yi)
    info("value of mean is $(value(s))")
end
```
- Output
```
INFO: value of mean is 0.06340121912925167
INFO: value of mean is -0.06576995293439102
INFO: value of mean is 0.05374292238752276
INFO: value of mean is 0.008857939006120167
INFO: value of mean is 0.016199508928045905
```

[go to top](#readme-contents)
