# Extending OnlineStats

Creating new OnlineStat types should be accomplished through [OnlineStatsBase.jl](https://github.com/joshday/OnlineStatsBase.jl), a lightweight package which defines the OnlineStats interface.

## Make a subtype of OnlineStat and give it a `fit!` method.

```julia
import OnlineStatsBase: fit!, ExactStat

mutable struct MyMean <: ExactStat{0}
    value::Float64
    MyMean() = new(0.0)
end

fit!(o::MyMean, y::Real, w::Float64) = (o.value += w * (y - o.value))
```

## That's all there is to it

```julia
using OnlineStats

y = randn(1000)

s = Series(MyMean(), Variance())

for yi in y
    fit!(s, yi)
end

value(s)
mean(y), var(y)
```

## Details

- An `ExactStat` is something that can be updated exactly.  A `StochasticStat` is something
  that must be approximated (typically through stochastic approximation).
  - `ExactStat` will use `EqualWeight` unless `default_weight` is overloaded.
  - `StochasticStat` will use `LearningRate` unless `default_weight` is overloaded.
- An OnlineStat is parameterized by the size of a single observation (and default weight).
  - 0: a `Number`, `Symbol`, or `String`
  - 1: an `AbstractVector` or `Tuple`
  - (1, 0): one of each
- OnlineStat Interface
  - `fit!(o, new_observation, w::Float64)`
    - Update the "sufficient statistics", not necessarily the value
  - `value(o)`
    - Create the value from the "sufficient statistics".  By default, this will return the first field of an OnlineStat
  - `merge!(o1, o2, w::Float64)`
    - merge `o2` into `o1`, where `w` is the amount of influence `o2` has.
- If you don't know the size of a single observation or the default weight 
  (`<:OnlineStat{Any,Any}`), define methods `OnlineStatsBase.input_ndims(::MyNewStat)` and 
  `OnlineStatsBase.default_weight(::MyNewStat)`.
