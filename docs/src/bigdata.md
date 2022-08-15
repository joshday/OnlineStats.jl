```@setup bigdata
ENV["GKSwstype"] = "100"
ENV["GKS_ENCODING"]="utf8"
```

# Big Data

## OnlineStats + CSV

The [CSV](https://github.com/JuliaData/CSV.jl) package offers a very memory-efficient way of iterating
through the rows of a (possibly larger-than-memory) CSV file.

### Example

Here is a toy example (Iris dataset) of how to iterate through the rows of a CSV file one-by-one
and calculate histograms grouped by another variable.

```@example bigdata
using OnlineStats, CSV, Plots

url = "https://gist.githubusercontent.com/joshday/df7bdaa1d58b398592e7656395de6335/raw/5a1c83f498f8ca7e25ff2372340e44b3389be9b1/iris.csv"

rows = CSV.Rows(download(url); reusebuffer = true)

itr = (string(row.variety) => parse(Float64, row.sepal_length) for row in rows)

o = GroupBy(String, Hist(4:0.25:8))

fit!(o, itr)

plot(o, layout=(3,1))
```

## Threaded Parallelism

The [ThreadsX](https://github.com/tkf/ThreadsX.jl) package offers multithreaded implementations of many functions in Base and supports OnlineStats via `ThreadsX.reduce(::OnlineStat, data)`.

- See ["A quick introduction to data parallelism in Julia"](https://juliafolds.github.io/data-parallelism/tutorials/quick-introduction/) by ThreadsX author Takafumi Arakaki (`@tkf`) for more details.

## Distributed Parallelism

`OnlineStat`s can be merged together to facilitate [Embarassingly parallel](https://en.wikipedia.org/wiki/Embarrassingly_parallel) computations.

!!! note
    In general, `fit!` is a cheaper operation than `merge!`.

!!! warn
    Not every `OnlineStat` can be merged.  In these cases, **OnlineStats** either uses an
    approximation or provides a warning that no merging occurred.

### Examples

#### Simplified (Not Actually in Parallel)

```julia
y1 = randn(10_000)
y2 = randn(10_000)
y3 = randn(10_000)

a = Series(Mean(), Variance(), KHist(20))
b = Series(Mean(), Variance(), KHist(20))
c = Series(Mean(), Variance(), KHist(20))

fit!(a, y1)
fit!(b, y2)
fit!(c, y3)

merge!(a, b)  # merge `b` into `a`
merge!(a, c)  # merge `c` into `a`
```

#### In Parallel

```julia
using Distributed
addprocs(3)
@everywhere using OnlineStats

s = @distributed merge for i in 1:3
    o = Series(Mean(), Variance(), KHist(20))
    fit!(o, randn(10_000))
end
```

```@raw html
<img src = "https://user-images.githubusercontent.com/8075494/57345083-95079780-7117-11e9-81bf-71b0469f04c7.png" style="width:400px">
```
