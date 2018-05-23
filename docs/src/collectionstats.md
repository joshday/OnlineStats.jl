# Collections of Stats

![](https://user-images.githubusercontent.com/8075494/40438658-3c4e8592-5e7e-11e8-97f1-76a749163de9.png)

```@setup collections 
using OnlineStats
```

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
g = Group(Mean(), CountMap(Bool))

itr = zip(randn(100), rand(Bool, 100))

fit!(g, itr)
```
