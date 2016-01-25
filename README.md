[![OnlineStats](http://pkg.julialang.org/badges/OnlineStats_0.4.svg)](http://pkg.julialang.org/?pkg=OnlineStats&ver=0.4)
[![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/x2t1ey2sgbmow1a4/branch/master?svg=true)](https://ci.appveyor.com/project/joshday/onlinestats-jl/branch/master)
[![codecov.io](http://codecov.io/github/joshday/OnlineStats.jl/coverage.svg?branch=josh)](http://codecov.io/github/joshday/OnlineStats.jl?branch=josh)


# OnlineStats

**Online algorithms for statistics.**

**OnlineStats** is a Julia package which provides online algorithms for statistical models.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.


# Overview

### Every OnlineStat is a Type

There are two ways of creating an OnlineStat:

1. Create "empty" object and add data
1. Create object with data

```julia
o = Mean()
fit!(o, y)

o = Mean(y)
```

### All OnlineStats can be updated

```julia
o = Variance(randn(100))
fit!(o, randn(100))
nobs(o) # number of observations == 200
```

### New data can be weighted differently

```julia
o = Mean(EqualWeight())
o2 = Variance(y, ExponentialWeight(.1))
o3 = QuantileMM(y, LearningRate(.6))
```

- `EqualWeight()`
    - all observations are weighted equally.  Weight at update `t` is `1 / t`.

- `ExponentialWeight(minstep::Float64)`, `ExponentialWeight(lookback::Int)`
    - use equal weight until weights reach `minstep = 1 / lookback`, then hold constant.  Weight at update `t` is `max(minstep, 1 / t)`.

- `LearningRate(r)`
    - `r` should be in (0.5, 1].
    - For stochastic approximation methods.  Weight at update `t` is `1 / t^r`.

- `LearningRate2(γ, c)`
    - `γ` > 0, `c` > 0
    - For stochastic approximation methods.  Weight at update `t` is `γ / (1 + γ * c * t)`.


### OnlineStats share a common interface

- `value(o)`
    - the associated value of an OnlineStat
- `nobs(o)`
    - the number of observations seen
- `nup(o)`
    - the number of updates performed (For `LeaningRate` only).  When using batch updates, `nobs(o) != n_updates(o)`.



# Advanced Usage

### New data can be updated in batches

Batch updates have an effect on convergence for stochastic approximation methods.
```julia
y = randn(1000)
o = QuantileMM(tau = [.25, .75])  # Online MM algorithm for quantiles
fit!(o, y, 10)  # update in batches of size 10
```
