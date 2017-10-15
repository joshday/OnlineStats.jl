# Series

The `Series` type is the workhorse of OnlineStats.  A Series tracks
1. The `Weight`
2. A tuple of OnlineStats.

## Creating
### Start "empty"
```julia
Series(Mean(), Variance())

Series(ExponentialWeight(), Mean(), Variance())
```
### Start with initial data
```julia
y = randn(100)

Series(y, Mean(), Variance())

Series(y, ExponentialWeight(.01), Mean(), Variance())

Series(ExponentialWeight(.01), y, Mean(), Variance())
```

## Updating

A Series can be updated with a single observation or a collection of observations.  

```julia
fit!(series, data)
```


### Single observation
!!! note
    A single observation depends on the OnlineStat.  For example, a single observation for a `Mean` is `Real` and for a `CovMatrix` is `AbstractVector` or `Tuple`.

```julia
s = Series(Mean())
fit!(s, randn())

s = Series(CovMatrix(4))
fit!(s, randn(4))
```
#### Single observation, override Weight
```julia
s = Series(Mean())
fit!(s, randn(), .1)
```
### Multiple observations
!!! note
    If a single observation is a Vector, a Matrix is ambiguous in how the observations are stored.  A `Rows()` (default) or `Cols()` argument can be added to the `fit!` call to specify observations are in rows or columns, respectively.

```julia
s = Series(Mean())
fit!(s, randn(100))

s = Series(CovMatrix(4))
fit!(s, randn(100, 4))          # Obs. in rows
fit!(s, randn(4, 100), Cols())  # Obs. in columns
```

#### Multiple observations, use the same weight for all
```julia
s = Series(Mean())
fit!(s, randn(100), .01)
```

#### Multiple observations, provide vector of weights
```julia
s = Series(Mean())
w = StatsBase.Weights(rand(100))
fit!(s, randn(100), w)
```

## Merging

Two Series can be merged if they track the same OnlineStats and those OnlineStats are
mergeable.

```julia
merge(series1, series2, arg)
merge!(series1, series2, arg)
```

Where `series1`/`series2` are Series that contain the same OnlineStats and `arg` is used to determine how `series2` should be merged into `series1`.


```julia
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
