# Weighting

OnlineStats are parameterized by a `Weight` type that determines the influence of the
next observation.  The `Weight` is always the last argument of the constructor.

![](images/weights.png)

## Weight Types

Many updates take the form of a weighted average.  For a current estimate $\theta^{(t-1)}$ and new value $x_t$, we update the estimate with:

$$\theta^{(t)} = (1 - \gamma_t) \theta^{(t-1)} + \gamma_t \; x_t$$  

Consider how the weights $\gamma_t$ affect the influence of the new value on the estimate.  The weight types below will be explained in terms of the weights $\gamma_t$.


### EqualWeight
```
EqualWeight()
```
Many online algorithms produce the same results as offline counterparts when using `EqualWeight`.  Each observation contributes equally.  This is the most common default.

$$\gamma_t = \frac{1}{t}$$


### ExponentialWeight
```
ExponentialWeight(λ::Float64)
ExponentialWeight(lookback::Int)
```
The update weight is constant, so newer observations have higher influence.

$$\gamma_t = \lambda$$

where `λ = 2 / (lookback + 1)`


### BoundedEqualWeight
```
BoundedEqualWeight(λ::Float64)
BoundedEqualWeight(lookback::Int)
```
Use `EqualWeight` until a minimum weight is reached, then uses `ExponentialWeight`

$$\gamma_t = \text{max}\left(\lambda, \frac{1}{t}\right)$$


### LearningRate
```
LearningRate(r::Float64 = .5, λ::Float64 = 0.0)
```
Mainly for algorithms using stochastic approximation.  The weights decrease at a "slow" rate
until reaching a minimum weight, then uses `ExponentialWeight`.

$$\gamma_t = \text{max}\left(\lambda, \frac{1}{t^r}\right), \quad r \in [.5, 1]$$


## Override the Weight

You can override an OnlineStat's Weight with an additional argument to `fit!`.  

```julia
y = randn(1000)
o = Mean(EqualWeight())
fit!(o, y, .01)  # use weight of .01 for each observation

wts = rand(1000)
fit!(o, y, wts)  # use weight of wts[i] for observation y[i]
```
