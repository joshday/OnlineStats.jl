# Series

`Series` is the workhorse of OnlineStats.  A Series acts as the manager for a single
OnlineStat or a tuple of OnlineStats.

## Creating
```julia
Series(Mean())
Series(Mean(), Variance())

Series(ExponentialWeight(), Mean())
Series(ExponentialWeight(), Mean(), Variance())

y = randn(100)
Series(y, Mean())
Series(y, Mean(), Variance())

Series(y, ExponentialWeight(), Mean())
Series(y, ExponentialWeight(), Mean(), Variance())
```

## Methods
- `value(s)`
  - map `value` to each of the OnlineStats held by the Series
- `stats(s)`
  - return the OnlineStat (if there's only one) or the tuple of OnlineStats held by the Series

## Updating
There are multiple ways to update the OnlineStats in a Series
- Single observation
```julia
s = Series(Mean())
fit!(s, randn())
```
- Single observation, override weight
```julia
s = Series(Mean())
fit!(s, randn(), rand())
```
- Multiple observations
```julia
s = Series(Mean())
fit!(s, randn(100))
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
  - Some OnlineStats perform differently when updated in minibatches, particularly those
  that use stochastic approximation (`QuantileSGD`, `QuantileMM`, `FitCauchy`, etc.)
```julia
s = Series(Mean())
fit!(s, randn(100), 7)
```

## Merging
```julia
s1 = Series(Mean(), Variance())
s2 = Series(Mean(), Variance())

y1, y2 = randn(100), randn(100)

fit!(s1, y1)
fit!(s2, y2)

merge!(s1, s2)

value(s1, 1) ≈ mean(vcat(y1, y2))
value(s1, 2) ≈ var(vcat(y1, y2))
```
