# Plotting

Plotting methods are provided by the [Plots](https://github.com/tbreloff/Plots.jl) package.

The same method can be used to create plots using Gadfly, Immerse, PyPlot, Qwt, etc.  You just need to specify the appropriate backend (`gadfly!()`, `qwt!()`, etc.).  Check out the Plots.jl documentation for more info.

### `traceplot!(o, b, args...; f::Function)`

- `traceplot!(o, batchsize, data...)`

Update an OnlineStat `o` with `data...` and create a traceplot of its history.
A snapshot of the statistic/model will be taken every `batchsize` observations.
At each snapshot, the value(s) `y = f(o)` is plotted at `x = nobs(o)`.

`f` is specified by a keyword argument that defaults to the first element returned by `state(o)`.

- Examples:

```julia
# coefficients of a stochastic gradient descent model
o = SGModel(size(x,2))
traceplot!(o, batchsize, x, y)

# Quantiles [.25, .5, .75] using online MM algorithm
o = QuantileMM()
traceplot!(o, batchsize, y)
```
