```@raw html
<div style="width:100%; height:150px;border-width:4px;border-style:solid;
        border-color:#2269D1;border-radius:10px;background-color:#6BFFE4;text-align:center;">
    <h1>Star us on GitHub!</h1>
    <a class="github-button" href="https://github.com/joshday/OnlineStats.jl" data-icon="octicon-star" data-size="large" data-show-count="true" aria-label="Star joshday/OnlineStats.jl on GitHub" style="margin:auto">Star</a>
    <script async defer src="https://buttons.github.io/buttons.js"></script>
</div>
```

# Home

**OnlineStats** is a Julia package for statistical analysis with algorithms that run both **online** and **in parallel**.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.

## Installation

```
import Pkg
Pkg.add("OnlineStats")
```

## Basics

### Every stat is `<: OnlineStat{T}`

(where `T` is the type of a single observation)

```@repl index
using OnlineStats
m = Mean()
supertype(typeof(m))
```

### Stats can be updated

`fit!(stat::OnlineStat{T}, y::S)` will iterate through `y` and `fit!` each element if `T != S`.

```@repl index
y = randn(100);
fit!(m, y)
```

### Stats can be merged

```@repl index
y2 = randn(100);
m2 = fit!(Mean(), y2)
merge!(m, m2)
```

### Stats have a value

```@repl index
value(m)
```

## Collections of Stats

```@raw html
<img src="https://user-images.githubusercontent.com/8075494/57342826-bf088c00-710e-11e9-9ac0-f3c1e5aa7a7d.png" style="width:400px">
```

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

## Additional Resources

- [OnlineStats Demos](https://github.com/joshday/OnlineStatsDemos)
- [JuliaDB Integration](http://juliadb.org/latest/onlinestats/)
