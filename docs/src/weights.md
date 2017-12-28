# Weight

`Series` is parameterized by a `Weight` type that controls the influence new observations.


Consider how weights affect the influence of the next observation on an online mean ``\theta^{(t)}``, as many `OnlineStat`s use updates of this form.  A larger weight  ``\gamma_t`` puts higher influence on the new observation ``x_t``:

```math
\theta^{(t)} = (1-\gamma_t)\theta^{(t-1)} + \gamma_t x_t
```

!!! note 
    The values produced by a weight must follow two rules:
    1. ``\gamma_1 = 1``
      - This guarantees ``\theta^{(1)} = x_1``
    1. ``\gamma_t \in (0, 1), \quad \forall t > 1``
      - This guarantees ``\theta^{(t)}`` stays inside a convex space

```@raw html
<br>
<img src="https://user-images.githubusercontent.com/8075494/29486708-a52b9de6-84ba-11e7-86c5-debfc5a80cca.png" height=450>
```

## [`EqualWeight()`](@ref)

Each observation has an equal amount of influence.  This is the default for subtypes of 
`EqualStat`, which can be updated exactly as the corresponding offline algorithm .

```math
\gamma_t = \frac{1}{t}
```

## [`ExponentialWeight(λ = 0.1)`](@ref)

Each observation is weighted with a constant, giving newer observations higher influence
and behaves similar to a rolling window.  `ExponentialWeight` is a good choice for observing 
real-time data streams where the true parameter may be changing over time.

```math
\gamma_t = \lambda
```

## [`LearningRate(r = 0.6)`](@ref)

Weights decrease at a slower rate than `EqualWeight` (if `r < 1`).  This is the default for
`StochasticStat` subtypes, which are based on stochastic approximation.  For `.5 < r < 1`,
each weight is between `1 / t` and `1 / sqrt(t)`.

```math
\gamma_t = \frac{1}{t^r}
```

## [`HarmonicWeight(a = 10.0)`](@ref)

Weights are based on a general harmonic series.

```math
\gamma_t = \frac{a}{a + t - 1}
```

## [`McclainWeight(a = 0.1)`](@ref)

Consider `McclainWeight` as a smoothed version of `Bounded{EqualWeight}`.  Weights approach
a positive constant `a` in the limit.

```math
\gamma_t = \frac{\gamma_{t-1}}{1 + \gamma_{t-1} - a}
```

## `Weight` Wrappers

Several types can change the behavior of a `Weight`.

### [`Bounded(weight, λ)`](@ref)

`Bounded` adds a minimum weight value.

```math
\gamma_t' = \text{max}(\gamma_t, λ)
```

### [`Scaled(weight, λ)`](@ref)

Weights are scaled by a constant.  This should only be used with certain subtypes of 
`StochasticStat` (those based on stochastic gradient algorithms), as it may violate the 
weight rules at the top of this page.  OnlineStats based on stochastic gradient algorithms 
are [`Quantile`](@ref), [`KMeans`](@ref), and [`StatLearn`](@ref).

```math
\gamma_t' = λ * \gamma_t
```


## Custom Weighting

You can implement your own `Weight` type via [OnlineStatsBase.jl](https://github.com/joshday/OnlineStatsBase.jl) or pass in a function to a `Series` in place of a weight.

```@repl 
using OnlineStats # hide

y = randn(100);

o = Mean()
Series(y, n -> 1/n, o)

value(o) ≈ mean(y)
```