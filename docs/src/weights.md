# Weight

`Series` is parameterized by a `Weight` type that controls the influence new observations.


Consider how weights affect the influence of the next observation on an online mean ``\theta^{(t)}``, as many `OnlineStat`s use updates of this form.  A larger weight  ``\gamma_t`` puts higher influence on the new observation ``x_t``:

```math
\theta^{(t)} = (1-\gamma_t)\theta^{(t-1)} + \gamma_t x_t
```

!!! note 
    The values produced by a `Weight` must follow two rules:
    1. ``\gamma_1 = 1`` (guarantees ``\theta^{(1)} = x_1``)
    1. ``\gamma_t \in (0, 1), \quad \forall t > 1`` (guarantees ``\theta^{(t)}`` stays inside a convex space)

```@raw html
<br>
<img src="https://user-images.githubusercontent.com/8075494/29486708-a52b9de6-84ba-11e7-86c5-debfc5a80cca.png" height=450>
```

## Weight Types
```@docs
EqualWeight
ExponentialWeight
LearningRate
HarmonicWeight
McclainWeight
```

## Weight wrappers

```@docs
Bounded
Scaled
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