# Weighting

OnlineStats are parameterized by a `Weight` type that determines the influence of the
next observation.  The `Weight` is always the last argument of the constructor.

```julia
# Example
o = CovMatrix(10, EqualWeight())
```

## Weight Types

### EqualWeight
Many online algorithms produce the same results as offline counterparts when using `EqualWeight`.  Each observation contributes equally.  This is the most common default.

### ExponentialWeight
The update weight is constant, so newer observations have higher influence.

### BoundedEqualWeight
Use `EqualWeight` until a minimum weight is reached, then uses `ExponentialWeight`

### LearningRate/LearningRate2
Mainly for algorithms using stochastic approximation.  The weights decrease at a "slow" rate.


## Override the Weight

You can override an OnlineStat's Weight with an additional argument to `fit!`

```julia
y = randn(1000)
o = Mean(EqualWeight())
fit!(o, y, .01)  # use weight of .01 for each observation

wts = rand(1000)
fit!(o, y, wts)  # use weight of wts[i] for observation y[i]
```
