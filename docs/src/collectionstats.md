# Collections of Stats

```@setup collections 
using OnlineStats
```

Several `OnlineStat`s act as a collection of other `OnlineStat`s.

## `Series`
A `Series` tracks stats that should be applied to the **same** data stream.

```@example collections
y = rand(1000)

s = Series(Mean(), Variance())
fit!(s, y)
```


## `FTSeries`
An `FTSeries` tracks stats that should be applied to the **same** data stream, but filters and transforms (hence `FT`) the input data before it is sent to its stats. 

```@example collections 
s = FTSeries(Mean(), Variance(); filter = x->true, transform = abs)
fit!(s, -y)
```


## `Group`
A `Group` tracks stats that should be applied to **different** data streams.

```@example collections 
g = Group(Mean(), Variance())
fit!(g, randn(1000, 2))
```
