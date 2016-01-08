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

#### `EqualWeight()`
- all observations are weighted equally.  Weight at update `t` is `1 / t`.

#### `ExponentialWeight(minstep)`, `ExponentialWeight(lookback)`
- use equal weight until weights reach `minstep = 1 / lookback`, then hold constant.  Weight at update `t` is `max(minstep, 1 / t)`.

#### `LearningRate(r)`
- For stochastic approximation methods.  Weight at update `t` is `1 / t^r`.

#### `LearningRate2(γ, c)`
- For stochastic approximation methods.  Weight at update `t` is `γ / (1 + γ * c * t)`.


### OnlineStats share a common interface

- `value(o)`
    - the associated value of an OnlineStat
- `nobs(o)`
    - the number of observations seen
- `n_updates(o)`
    - the number of update performed.  When using batch updates, `nobs(o) != n_updates(o)`.
