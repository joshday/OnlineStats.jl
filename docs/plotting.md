# Plotting

Plotting methods are provided by [Plots.jl](https://github.com/tbreloff/Plots.jl).  Plots.jl uses a common interface for calling multiple plotting package backends.  This allows OnlineStats to simultaneously provide plot methods for PyPlot, Gadfly, Immerse, etc.

### Basic Trace Plots

Initialize a traceplot with `tr = TracePlot(o::OnlineStat, f::Function)`.  Then, each call to `update!(tr, data...)` will update `o` and add a new observation to the plot where `x = nobs(o)` and `y = tr.f(o)`.


Example:
```julia
o = StochasticModel(size(x,2))
tr = TracePlot(o, StatsBase.coef)

update!(tr, x1, y1)
update!(tr, x2, y2)
...
```
