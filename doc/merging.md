# Merging Series

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

# Provide the ratio of influence o2 should have.
merge!(s1, s2, .5)
```
