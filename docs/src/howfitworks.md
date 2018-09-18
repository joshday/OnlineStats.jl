```@setup howfitworks
using OnlineStats
```

# How `fit!` Works

- Stats are subtypes of `OnlineStat{T}` where `T` is the type of a single observation.
    - E.g. `Mean <: OnlineStat{Number}`
- When you try to `fit!(o::OnlineStat{T}, data::T)`, `o` will be updated with the single observation `data`.
- When you try to `fit!(o::OnlineStat{T}, data::S)`, OnlineStats will attempt to iterate through `data` and `fit!` each item.


## Why is Fitting Based on Iteration?

### Reason 1: OnlineStats doesn't want to make assumptions on the shape of your data

Consider `CovMatrix`, for which a single observation is an `AbstractVector`, `Tuple`, or `NamedTuple`.
If I try to update it with a `Matrix`, it's ambiguous whether I want *rows* or *columns* of 
the matrix to be treated as individual observations.  

By default, OnlineStats will try observations-in-rows, but you can alternately/explicitly 
use the [`OnlineStatsBase.eachrow`](@ref) and [`OnlineStatsBase.eachcol`](@ref) functions, which efficiently iterate over 
the rows or columns of the matrix, respectively.


```@example howfitworks
fit!(CovMatrix(), eachrow(randn(1000,2)))

fit!(CovMatrix(), eachcol(randn(2,1000)))
```

### Reason 2: OnlineStats naturally works out-of-the-box with many data structures

Tabular data structures such as those in [JuliaDB](https://github.com/JuliaComputing/JuliaDB.jl)
iterate over named tuples of rows, so things like this just work:

```julia
using JuliaDB

t = table(randn(100), randn(100))

fit!(2Mean(), t)
```


## A Common Error

Consider the following example:

```@repl howfitworks
fit!(Mean(), "asdf")
```

This causes an error because:

1. `"asdf"` is not a `Number`, so OnlineStats attempts to iterate through it
2. Iterating through `"asdf"` begins with the character `'a'`