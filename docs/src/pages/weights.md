# Weighting

Series are parameterized by a `Weight` type that controls the influence of the next observation.

Consider how the following weighting schemes affect the influence of the next observation on an online mean.  Many OnlineStats have an update of this form:

```math
\theta^{(t)} = (1-\gamma_t)\theta^{(t-1)} + \gamma_t x_t
```
![](https://user-images.githubusercontent.com/8075494/27964520-908491d4-6306-11e7-9bef-0634359e5aa6.png)


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

## [`BoundedEqualWeight(λ)`](@ref)
- Use `EqualWeight` until a threshold is hit, then stay constant.
```math
\gamma_t = \text{max}\left(\frac{1}{t}, \lambda\right)
```

## [`LearningRate(r, λ)`](@ref)  
- Decrease at a slow rate until a threshold is hit.
```math
\gamma_t = \text{max}\left(\frac{1}{t^r}, \lambda\right)
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
