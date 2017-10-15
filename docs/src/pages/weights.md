# Weighting

Series are parameterized by a `Weight` type that controls the influence of the next observation.

Consider how weights affect the influence of the next observation on an online mean ``\theta^{(t)}``, as many OnlineStats use updates of this form.  A larger weight  ``\gamma_t`` puts higher influence on the new observation ``x_t``:

```math
\theta^{(t)} = (1-\gamma_t)\theta^{(t-1)} + \gamma_t x_t
```

![](https://user-images.githubusercontent.com/8075494/29486708-a52b9de6-84ba-11e7-86c5-debfc5a80cca.png)

![](https://user-images.githubusercontent.com/8075494/31586782-0050e6de-b1a4-11e7-9ada-895c7aeb6a90.gif)


## [`EqualWeight()`](@ref)  
- Each observation has an equal amount of influence.
```math
\gamma_t = \frac{1}{t}
```

## [`ExponentialWeight(λ)`](@ref)  
- Each observation is weighted with a constant, giving newer observations higher influence.
```math
\gamma_t = \lambda
```

## [`LearningRate(r)`](@ref)  
- Decrease at a slow rate.
```math
\gamma_t = \frac{1}{t^r}
```  

## [`HarmonicWeight(a)`](@ref)  
- Decrease at a slow rate.
```math
\gamma_t = \frac{a}{a + t - 1}
```  

## [`McclainWeight(a)`](@ref)  
- Smoothed version of `BoundedEqualWeight`.
```math
\gamma_t = \frac{\gamma_{t-1}}{1 + \gamma_{t-1} - a}
```

## [`Bounded(weight, λ)`](@ref)
- Wrapper for a weight which provides a minimum bound
```math
\gamma_t' = \text{max}(\gamma_t, λ)
```

## [`Scaled(weight, λ)`](@ref)
- Wrapper for a weight which scales the weight by a constant.  This is only meant for use with stochastic gradient algorithms.
```math
\gamma_t' = λ * \gamma_t
```
