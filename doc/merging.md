# Merging OnlineStats

Some OnlineStat objects can be merged together.  The syntax for in-place merging is

```julia
merge!(o1, o2, arg)
```

Where `o1`/`o2` are OnlineStats of the same type and `arg` is used to determine how the value(s) from `o2` should be merged into `o1`.


```julia
y1 = randn(100)
y2 = randn(100)

o1 = Mean(y1)
o2 = Mean(y2)

# Treat o2 as a new batch of data.  Essentially:
# o1 = Mean(y1); fit!(o1, y2)
merge!(o1, o2 :append)

# Use weighted average based on nobs of each OnlineStat
merge!(o1, o2 :mean)

# Treat o2 as a single observation.  Essentially:
# o1 = Mean(y1); fit!(o1, mean(y2))
merge!(o1, o2 :singleton)

# Provide the ratio of influence o2 should have.
w = .5
merge!(o1, o2, w)
```
