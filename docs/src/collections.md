# Collections of Stats

There are a few special `OnlineStats` that group together other `OnlineStats`: [`Series`](@ref) and [`Group`](@ref).

```@raw html
<img src="https://user-images.githubusercontent.com/8075494/57342826-bf088c00-710e-11e9-9ac0-f3c1e5aa7a7d.png" style="width:400px">
```

```@setup collections
using OnlineStats
```

## `Series`
A [`Series`](@ref) tracks stats that should be applied to the **same** data stream.

```@example collections
y = rand(1000)

s = Series(Mean(), Variance())

fit!(s, y)
```

## `Group`

A [`Group`](@ref) tracks stats that should be applied to **different** data streams.

```@example collections
g = Group(Mean(), CountMap(Bool))

itr = zip(randn(100), rand(Bool, 100))

fit!(g, itr)
```
