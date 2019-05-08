```@setup howfitworks
using OnlineStats
```

# How `fit!` Works

## Core Principles

1. Stats are subtypes of `OnlineStat{T}` where `T` is the type of a single observation.
    - E.g. `Mean <: OnlineStat{Number}`
2. `fit!(o::OnlineStat{T}, data::T)`
    - Update `o` with the single observation `data`.
3. `fit!(o::OnlineStat{T}, data::S)`
    - Iterate through `data` and `fit!` each item.


## Why is Fitting Based on Iteration?

### Reason 1: OnlineStats doesn't make assumptions on the shape of your data

Consider `CovMatrix`, for which a single observation is an `AbstractVector`, `Tuple`, or `NamedTuple`.
If I try to update it with a `Matrix`, it's ambiguous whether I want *rows* or *columns* of
the matrix to be treated as individual observations.

!!! note
    Use `eachrow` and `eachcol` (from `LinearAlgebra`) to choose what to iterate over.
    For Julia versions less than 1.1, use `OnlineStats.eachrow` and `OnlineStats.eachcol`.


```@example howfitworks
x = randn(1000, 2)

fit!(CovMatrix(), eachrow(x))

fit!(CovMatrix(), eachcol(x'))
```

### Reason 2: OnlineStats works out-of-the-box with many data structures

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