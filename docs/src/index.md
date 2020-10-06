```@raw html
<div style="width:100%; height:150px;border-width:4px;border-style:solid;padding-top:25px;
        border-color:#000;border-radius:10px;text-align:center;background-color:#B3D8FF;
        color:#000">
    <h3 style="color: black;">Star us on GitHub!</h3>
    <a class="github-button" href="https://github.com/joshday/OnlineStats.jl" data-icon="octicon-star" data-size="large" data-show-count="true" aria-label="Star joshday/OnlineStats.jl on GitHub" style="margin:auto">Star</a>
    <script async defer src="https://buttons.github.io/buttons.js"></script>
</div>
```

# Welcome!

**OnlineStats** does statistics and data visualization for big/streaming data via [**online algorithms**](https://en.wikipedia.org/wiki/Online_algorithm).  Each algorithm:

1. processes data one observation at a time.
2. uses O(1) memory.


## Basics

### 1) Creating

- Stats are subtypes of `OnlineStat{T}` where `T` is the type of a single observation.

```@repl index
using OnlineStats
m = Mean()
supertype(Mean)
```

### 2) Updating

- Stats can be updated with single or multiple observations e.g. `fit!(m, 1)` and `fit!(m, [1,2,3])`.

```@repl index
y = randn(100);
fit!(m, y)
value(m)
```

### 3) Merging

- Stats can be merged.

```@repl index
y2 = randn(100);
m2 = fit!(Mean(), y2)
merge!(m, m2)
```

!!! warn
    Some `OnlineStat`s are not analytically mergeable.  In these cases, you will see a warning that 
    either no merging occurred or that the merge is approximate.
