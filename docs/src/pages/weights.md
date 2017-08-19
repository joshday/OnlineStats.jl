# Weighting

Series are parameterized by a `Weight` type that controls the influence of the next observation.

Consider how the following weighting schemes affect the influence of the next observation on an online mean.  Many OnlineStats have an update of this form:

```math
\theta^{(t)} = (1-\gamma_t)\theta^{(t-1)} + \gamma_t x_t
```
![](https://user-images.githubusercontent.com/8075494/29486708-a52b9de6-84ba-11e7-86c5-debfc5a80cca.png)


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
- Decrease at a slow rate until a threshold is hit.
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
