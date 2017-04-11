# Callbacks

While an OnlineStat is being updated, you may wish to perform an action like print intermediate results to a log file or update a plot.  For this purpose, OnlineStats exports a `maprows` function.

`maprows(f::Function, b::Integer, data...)`

`maprows` works similar to `Base.mapslices`, but maps `b` rows at a time.  It is best used with Julia's do block syntax.

## Example 1
### Input
```julia
y = randn(100)
s = Series(Mean())
maprows(20, y) do yi
    fit!(s, yi)
    info("value of mean is $(value(s))")
end
```
### Output
```
INFO: value of mean is 0.06340121912925167
INFO: value of mean is -0.06576995293439102
INFO: value of mean is 0.05374292238752276
INFO: value of mean is 0.008857939006120167
INFO: value of mean is 0.016199508928045905
```
