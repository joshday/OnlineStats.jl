# Parallel Computation

Two `Series` can be merged if they track the same `OnlineStat`s, which facilitates [embarassingly parallel](https://en.wikipedia.org/wiki/Embarrassingly_parallel) computations.  Merging in **OnlineStats** is used by [JuliaDB](https://github.com/JuliaComputing/JuliaDB.jl) to run analytics in parallel on large persistent datasets.

!!! note
    In general, `fit!` is a cheaper operation than `merge!`.

## ExactStat merges

Many `OnlineStat`s are subtypes of `ExactStat`, meaning the value of interest can be
calculated exactly (compared to the appropriate offline algorithm).  For these OnlineStats,
the order of `fit!`-ting and `merge!`-ing does not matter.  See `subtypes(OnlineStats.ExactStat)`
for a full list.

```julia
y1 = randn(10_000)
y2 = randn(10_000)
y3 = randn(10_000)

s1 = Series(Mean(), Variance(), Hist(50))
s2 = Series(Mean(), Variance(), Hist(50))
s3 = Series(Mean(), Variance(), Hist(50))

fit!(s1, y1)
fit!(s2, y2)
fit!(s3, y3)

merge!(s1, s2)  # merge information from s2 into s1
merge!(s1, s3)  # merge information from s3 into s1
```

```@raw html
<img width = 500 src = "https://user-images.githubusercontent.com/8075494/32748459-519986e8-c88a-11e7-89b3-80dedf7f261b.png">
```

## Other Merges

For `OnlineStat`s that rely on approximations, merging isn't always a well-defined operation.
In these cases, a warning will print that merging did not occur.  Please open an [issue](https://github.com/joshday/OnlineStats.jl/issues) to discuss merging an
`OnlineStat` if merging fails but you believe it should be merge-able.