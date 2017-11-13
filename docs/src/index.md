# Basics

**OnlineStats** is a Julia package which provides online algorithms for statistical models.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.

### Every OnlineStat is a type

```julia
m = Mean()
v = Variance()
```

### OnlineStats are grouped by [`Series`](@ref)

```julia
s = Series(m, v)
```

### Updating a Series updates the OnlineStats

```julia
y = randn(100)

for yi in y
    fit!(s, yi)
end

# or more simply:
fit!(s, y)
```

```@raw html
<img width = 200 src = "https://user-images.githubusercontent.com/8075494/32734476-260821d0-c860-11e7-8c91-49ba0b86397a.gif">
```
