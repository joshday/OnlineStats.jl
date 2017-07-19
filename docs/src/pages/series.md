# Series

The `Series` type is the workhorse of OnlineStats.  A Series tracks
1. The `Weight`
2. An OnlineStat or tuple of OnlineStats.

## Creating
- Start "empty"
```julia
Series(Mean())
Series(Mean(), Variance())

Series(ExponentialWeight(), Mean())
Series(ExponentialWeight(), Mean(), Variance())
```
- Start with initial data
```julia
y = randn(100)

Series(y, Mean())
Series(y, Mean(), Variance())

Series(y, ExponentialWeight(.01), Mean())
Series(y, ExponentialWeight(.01), Mean(), Variance())

Series(ExponentialWeight(.01), y, Mean())
Series(ExponentialWeight(.01), y, Mean(), Variance())
```

## Updating
#### Single observation
!!! note
    The input type of the OnlineStat(s) determines what a single observation is.  For a `Mean`, a single observation is a `Real`.  For OnlineStats such as `CovMatrix`, a single observation is an `AbstractVector` or `NTuple`.

```julia
s = Series(Mean())
fit!(s, randn())

s = Series(CovMatrix(4))
fit!(s, randn(4))
fit!(s, randn(4))
```
#### Single observation, override weight
```julia
s = Series(Mean())
fit!(s, randn(), .1)
```
#### Multiple observations
!!! note
    The input type of the OnlineStat(s) determines what multiple observations are.  For a `Mean`, this would be a `AbstractVector`.  For a `CovMatrix`, this would be an `AbstractMatrix`.  By default, each *row* is considered an observation.  You can use column observations with `ObsDim.Last()` (see below).

```julia
s = Series(Mean())
fit!(s, randn(100))

s = Series(CovMatrix(4))
fit!(s, randn(100, 4))                 # Obs. in rows
fit!(s, randn(4, 100), ObsDim.Last())  # Obs. in columns
```
#### Multiple observations, use the same weight for all
```julia
s = Series(Mean())
fit!(s, randn(100), .01)
```
#### Multiple observations, provide vector of weights
```julia
s = Series(Mean())
fit!(s, randn(100), rand(100))
```

## Merging

Two Series can be merged if they track the same OnlineStats and those OnlineStats are
mergeable.  The syntax for in-place merging is

```julia
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
