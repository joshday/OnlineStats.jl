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


## Callbacks

While an OnlineStat is being updated, you may wish to perform an action like print intermediate results to a log file or update a plot.  For this purpose, OnlineStats exports a [`maprows`](@ref) function.

`maprows(f::Function, b::Integer, data...)`

`maprows` works similar to `Base.mapslices`, but maps `b` rows at a time.  It is best used with Julia's do block syntax.

- Input
```julia
y = randn(100)
s = Series(Mean())
maprows(20, y) do yi
    fit!(s, yi)
    info("value of mean is $(value(s))")
end
```
- Output
```
INFO: value of mean is 0.06340121912925167
INFO: value of mean is -0.06576995293439102
INFO: value of mean is 0.05374292238752276
INFO: value of mean is 0.008857939006120167
INFO: value of mean is 0.016199508928045905
```
