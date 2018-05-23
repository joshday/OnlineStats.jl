# Basics

**OnlineStats** is a Julia package for statistical analysis with algorithms that run both **online** and **in parallel**..  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.

## Installation

```
Pkg.add("OnlineStats")
```

## Basics

### Every Stat is `<: OnlineStat`

```@repl index
using OnlineStats

m = Mean()
```

### Stats Can Be Updated

```@repl index
y = randn(100);

fit!(m, y)
```

### Stats Can Be Merged 

```@repl index 
y2 = randn(100);

m2 = fit!(Mean(), y2)

merge!(m, m2)
```

### Stats Have a Value 

```@repl index
value(m)
```

## Details of `fit!`-ting

Stats are subtypes of the parametric abstract type `OnlineStat{T}`, where `T` is the type of a single observation.  For example, `Mean <: OnlineStat{Number}`.  

- One of the two `fit!` methods updates the stat from a single observation:

```
fit!(::OnlineStat{T}, x::T) = ...
```

- In any other case, OnlineStats will attempt to iterate through `x` and `fit!` each 
  element (with checks to avoid stack overflows).

```
function fit!(o::OnlineStat{T}, y::S) where {T, S}
    for yi in y 
        fit!(o, yi)
    end
    o
end
```

### A Common Error

```@repl index
fit!(Mean(), "asdf")
```

Here is what's happening:

1. `String` is not a subtype of `Number`, so OnlineStats attempts to iterate through "asdf". 
1. The first element of `"asdf"` is the `Char` `'a'`.
1. The above error is produced (rather than a stack overflow).

When you see this error:

1. Check that `eltype(x)` in `fit!(stat, x)` is what you think it is.
1. Check if the stat is parameterized by observation type (use `?Stat`)
    - i.e. `Extrema` is a parametric type that defaults to `Float64`.  If my data is 
      `Int64`, I need to use `Extrema(Int64)`.

### Helper functions

To iterate over the rows/columns of a matrix, use [`eachrow`](@ref) or [`eachcol`](@ref), respectively.

```@example index
fit!(CovMatrix(), eachrow(randn(100,2)))
```
