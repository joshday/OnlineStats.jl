# Basics

**OnlineStats** is a Julia package which provides *online parallelizable algorithms* for statistics.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.

## Installation

```
Pkg.add("OnlineStats")
```

## Summary of Usage

### Every statistic/model is a type (<: OnlineStat)

```julia
using OnlineStats 

m = Mean()
v = Variance()
```

### `OnlineStat`s are grouped by `Series`

```julia
s = Series(m, v)
```

### Updating a `Series` updates the contained `OnlineStat`s

```julia
y = randn(1000)

# for yi in y
#     fit!(s, yi)
# end
fit!(s, y)
```

### `OnlineStat`s have a `value`

```
value(m) ≈ mean(y)    
value(v) ≈ var(y)  
```


### `Series` and `OnlineStat`s can be merged

See [Parallel Computation](@ref).

```
y2 = randn(123)

s2 = Series(y2, Mean(), Variance())

merge!(s, s2)

value(m) ≈ mean(vcat(y, y2))    
value(v) ≈ var(vcat(y, y2))  
```

## Much more than means and variances

**OnlineStats can do a lot**.  See [Statistics and Models](@ref).

```@raw html
<img width = 200 src = "https://user-images.githubusercontent.com/8075494/32734476-260821d0-c860-11e7-8c91-49ba0b86397a.gif">
```