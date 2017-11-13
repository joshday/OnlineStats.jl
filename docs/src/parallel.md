# Parallel Computation

Two Series can be merged if they track the same OnlineStats.  This facilitates [embarassingly parallel](https://en.wikipedia.org/wiki/Embarrassingly_parallel) computations.  In general, `fit!`
is a cheaper operation than `merge!` and should be preferred.

## ExactStat merges

Many OnlineStats are subtypes of `ExactStat`, meaning the value of interest can be
calculated exactly (compared to the appropriate offline algorithm).  For these OnlineStats,
the order of `fit!`-ting and `merge!`-ing does not matter.  See `subtypes(OnlineStats.ExactStat)`
for a full list.

```julia
# NOTE: This code is not actually running in parallel
y1 = randn(10_000)
y2 = randn(10_000)
y3 = randn(10_000)

s1 = Series(Mean(), Variance(), IHistogram(50))
s2 = Series(Mean(), Variance(), IHistogram(50))
s3 = Series(Mean(), Variance(), IHistogram(50))

fit!(s1, y1)
fit!(s2, y2)
fit!(s3, y3)

merge!(s1, s2)  # merge information from s2 into s1
merge!(s1, s3)  # merge information from s3 into s1
```

![](https://user-images.githubusercontent.com/8075494/32748459-519986e8-c88a-11e7-89b3-80dedf7f261b.png)

## Other Merges

For OnlineStats which rely on approximations, merging isn't always a well-defined operation.
A printed warning will occur for these cases.  Please open an issue to discuss merging an
OnlineStat if merging fails but you believe it should be merge-able.