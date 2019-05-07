# Parallel Computation

`OnlineStat`s can be merged together to facilitate [Embarassingly parallel](https://en.wikipedia.org/wiki/Embarrassingly_parallel) computations.  For example, merging in **OnlineStats** is used under the hood by [**JuliaDB**](https://github.com/JuliaComputing/JuliaDB.jl) to run analytics in parallel.


!!! note
    In general, `fit!` is a cheaper operation than `merge!`.

!!! warn
    Not every `OnlineStat` can be merged.  In these cases, **OnlineStats** either uses an
    approximation or provides a warning that no merging occurred.

## Example

```julia
y1 = randn(10_000)
y2 = randn(10_000)
y3 = randn(10_000)

s1 = Series(Mean(), Variance(), KHist(50))
s2 = Series(Mean(), Variance(), KHist(50))
s3 = Series(Mean(), Variance(), KHist(50))

fit!(s1, y1)
fit!(s2, y2)
fit!(s3, y3)

merge!(s1, s2)  # merge information from s2 into s1
merge!(s1, s3)  # merge information from s3 into s1
```

```@raw html
<img width = 500 src = "https://user-images.githubusercontent.com/8075494/32748459-519986e8-c88a-11e7-89b3-80dedf7f261b.png">
```