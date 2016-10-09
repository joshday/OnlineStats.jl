# Callbacks

While an OnlineStat is being updated, you may wish to perform an action like print intermediate results to a log file or update a plot.  For this purpose, OnlineStats exports a `maprows` function.

`maprows(f::Function, b::Integer, data...)`

`maprows` works similar to `Base.mapslices`, but maps `b` rows at a time.  It is best used with Julia's do block syntax.

## Example 1
### Input
```julia
y = randn(100)
o = Mean()
maprows(20, y) do yi
    fit!(o, yi)
    info("value of mean is $(mean(o))")
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

## Example 2
### Input
```julia
using Plots; pyplot()
y = randn(10_000)

o = QuantileMM(LearningRate(.7), tau = [.25, .5, .75])

plt = plot(zeros(1, 3), zeros(1, 3))       # initialize plot

maprows(50, y) do yi              # for each batch of 50 observations
    fit!(o, yi, 5)                 # fit in minibatches of 5
    push!(plt, nobs(o), value(o))  # Add a value to the plot
end

display(plt)
```
### Output
![](https://cloud.githubusercontent.com/assets/8075494/18796290/978802e2-8196-11e6-8097-b65b722376fc.png)
