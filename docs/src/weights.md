# Weights

Many `OnlineStat`s are parameterized by a `Weight` that controls the influence of new observations.  If the `OnlineStat` is capable of calculating the same result as a corresponding offline estimator, it will have a keyword argument `weight`.  If the `OnlineStat` uses stochastic approximation, it will have a keyword argument `rate`.

Consider how weights affect the influence of the next observation on an online mean ``\theta^{(t)}``, as many `OnlineStat`s use updates of this form.  A larger weight  ``\gamma_t`` puts higher influence on the new observation ``x_t``:

```math
\theta^{(t)} = (1-\gamma_t)\theta^{(t-1)} + \gamma_t x_t
```

!!! note
    The values produced by a `Weight` must follow two rules:
    1. ``\gamma_1 = 1`` (guarantees ``\theta^{(1)} = x_1``)
    2. ``\gamma_t \in (0, 1), \quad \forall t > 1`` (guarantees ``\theta^{(t)}`` stays inside a convex space)

```@raw html
<br>
<img src="https://user-images.githubusercontent.com/8075494/57347301-cc7a4200-711f-11e9-86e5-385e4f77f069.png" style="width:400">
```

## Weight Types

```@docs
EqualWeight
ExponentialWeight
LearningRate
LearningRate2
HarmonicWeight
McclainWeight
```

## Custom Weighting

The `Weight` can be any callable object that receives the number of observations as its argument.  For example:

- `weight = inv` will have the same result as `weight = EqualWeight()`.
- `weight = x -> x == 1 ? 1.0 : .01` will have the same result as `weight = ExponentialWeight(.01)`

```@repl
using OnlineStats # hide
y = randn(100);

fit!(Mean(weight = EqualWeight()), y)
fit!(Mean(weight = inv), y)

fit!(Mean(weight = ExponentialWeight(.01)), y)
fit!(Mean(weight = x -> x == 1 ? 1.0 : .01), y)
```

## Example of Weight Effects using Data with [Concept Drift](https://en.wikipedia.org/wiki/Concept_drift)

```@raw html
<br>
<img src="https://user-images.githubusercontent.com/8075494/57347308-d4d27d00-711f-11e9-8fbe-fc4523b96b48.gif" style="width:400">
```