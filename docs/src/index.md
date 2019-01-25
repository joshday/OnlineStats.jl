# Home

**OnlineStats** is a Julia package for statistical analysis with algorithms that run both **online** and **in parallel**.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.

## Installation

```
import Pkg
Pkg.add("OnlineStats")
```

## Basics

- Every stat is `<: OnlineStat{T}`
    -  `T` is the type of a single observation.

```@example index
using OnlineStats

m = Mean()
```

```@example index
supertype(typeof(m))
```

- Stats can be updated.
    - `fit!(stat::OnlineStat{T}, y::S)` will iterate through y if `T != S`.

```@example index
y = randn(100)

fit!(m, y)
```

- Stats can be merged.

```@example index 
y2 = randn(100);

m2 = fit!(Mean(), y2)

merge!(m, m2)
```

- Stats have a value

```@example index
value(m)
```
## Collections of Stats

![](https://user-images.githubusercontent.com/8075494/40438658-3c4e8592-5e7e-11e8-97f1-76a749163de9.png)

```@setup collections 
using OnlineStats
```

### `Series`
A `Series` tracks stats that should be applied to the **same** data stream.

```@example collections
y = rand(1000)

s = Series(Mean(), Variance())
fit!(s, y)
```


### `FTSeries`
An `FTSeries` tracks stats that should be applied to the **same** data stream, but filters and transforms (hence `FT`) the input data before it is sent to its stats. 

```@example collections 
s = FTSeries(Mean(), Variance(); filter = x->true, transform = abs)
fit!(s, -y)
```


### `Group`
A `Group` tracks stats that should be applied to **different** data streams.

```@example collections 
g = Group(Mean(), CountMap(Bool))

itr = zip(randn(100), rand(Bool, 100))

fit!(g, itr)
```

## Resources

- [OnlineStats Demos](https://github.com/joshday/OnlineStatsDemos)
- [JuliaDB Integration](http://juliadb.org/latest/onlinestats/)