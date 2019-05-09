# Parallel Computation

`OnlineStat`s can be merged together to facilitate [Embarassingly parallel](https://en.wikipedia.org/wiki/Embarrassingly_parallel) computations.  For example, merging in **OnlineStats** is used under the hood by [**JuliaDB**](https://github.com/JuliaComputing/JuliaDB.jl) to run analytics in parallel.


!!! note
    In general, `fit!` is a cheaper operation than `merge!`.

!!! warn
    Not every `OnlineStat` can be merged.  In these cases, **OnlineStats** either uses an
    approximation or provides a warning that no merging occurred.

## Example

### Simplified (Not Actually in Parallel)

```julia
y1 = randn(10_000)
y2 = randn(10_000)
y3 = randn(10_000)

s1 = Series(Mean(), Variance(), KHist(20))
s2 = Series(Mean(), Variance(), KHist(20))
s3 = Series(Mean(), Variance(), KHist(20))

fit!(s1, y1)
fit!(s2, y2)
fit!(s3, y3)

merge!(s1, s2)  # merge information from s2 into s1
merge!(s1, s3)  # merge information from s3 into s1
```

### In Parallel

```julia
using Distributed
addprocs(3)
@everywhere using OnlineStats

@distributed merge! for i in 1:3
    s = fit!(Series(Mean(), Variance(), KHist(20)), randn(10_000))
end
```

```@raw html
<img src = "https://user-images.githubusercontent.com/8075494/57345083-95079780-7117-11e9-81bf-71b0469f04c7.png" style="width:400px">
```