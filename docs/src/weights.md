# Weighting

Series are parameterized by a `Weight` type that controls the influence of the next observation.

Consider how weights affect the influence of the next observation on an online mean ``\theta^{(t)}``, as many OnlineStats use updates of this form.  A larger weight  ``\gamma_t`` puts higher influence on the new observation ``x_t``:

```math
\theta^{(t)} = (1-\gamma_t)\theta^{(t-1)} + \gamma_t x_t
```

!!! note 
    The values produced by a weight must follow two rules:
    - ``\gamma_1 = 1``
      - This guarantees ``\theta^{(1)} = x_1``
    - ``\gamma_t \in (0, 1), \quad \forall t > 1``
      - This guarantees ``\theta^{(t)}`` stays inside a convex space

```@raw html
<br>
<img src="https://user-images.githubusercontent.com/8075494/29486708-a52b9de6-84ba-11e7-86c5-debfc5a80cca.png" height=300>
```

## [`EqualWeight()`](@ref)

- Each observation has an equal amount of influence.

```math
\gamma_t = \frac{1}{t}
```

## [`ExponentialWeight(λ = 0.1)`](@ref)

- Each observation is weighted with a constant, giving newer observations higher influence.

```math
\gamma_t = \lambda
```

## [`LearningRate(r = 0.6)`](@ref)

- Decrease at a slow rate.

```math
\gamma_t = \frac{1}{t^r}
```

## [`HarmonicWeight(a = 10.0)`](@ref)

- Decrease at a slow rate.

```math
\gamma_t = \frac{a}{a + t - 1}
```

## [`McclainWeight(a = 0.1)`](@ref)

- Smoothed version of `Bounded{EqualWeight}`.  Weight approaches `a` in the limit.

```math
\gamma_t = \frac{\gamma_{t-1}}{1 + \gamma_{t-1} - a}
```

## [`Bounded(weight, λ)`](@ref)

- Wrapper for a weight which provides a minimum bound.

```math
\gamma_t' = \text{max}(\gamma_t, λ)
```

## [`Scaled(weight, λ)`](@ref)

- Wrapper for a weight which scales the weight by a constant.  This is only meant for use
  with subtypes of `StochasticStat`, as it violates the rule ``\gamma_1 = 1``.

```math
\gamma_t' = λ * \gamma_t
```
