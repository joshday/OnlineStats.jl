# Basics

**OnlineStats** is a Julia package for statistical analysis with algorithms that run both **online** and **in parallel**..  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.

## Installation

```
Pkg.add("OnlineStats")
```

## Basics

### Every Stat is `<: OnlineStat`

```@example index
using OnlineStats

m = Mean()
```

### Stats Can Be Updated

```@example index
y = randn(100)

fit!(m, y)
```

### Stats Can Be Merged 

```@example index 
y2 = randn(100)

m2 = fit!(Mean(), y2)

merge!(m, m2)
```

### Stats Have a Value 

```@example index
value(m)
```

## Details of `fit!`-ting

The second argument to `fit!` can be either a single observation or an iterator of observations.
Naturally, a `Mean` accepts a number as its input, so when a vector of numbers is provided,
`fit!` updates the `Mean` one element at a time by iterating through the vector.

A slightly more complicated example is when the input is a vector, such as a covariance 
matrix ([`CovMatrix](@ref)).  When a matrix is provided, OnlineStats will iterate over the 
**rows** of the matrix.

```@example index
fit!(CovMatrix(), randn(100, 2))
```

We can also explictly iterate over the **rows** or **columns** with [`eachrow`](@ref) and 
[`eachcol`](@ref), respectively.

```@example index
fit!(CovMatrix(), eachrow(randn(100, 2)))
```

```@example index
fit!(CovMatrix(), eachcol(randn(100, 2)))
```