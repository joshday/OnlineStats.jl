# Overview

### Each statistic has its own type  
For example:

- `Summary` (mean, var, max, min)
- `CovarianceMatrix`
- `QuantileSGD` (stochastic subgradient descent algorithm for quantiles)
- `OnlineFitNormal` (normal density estimate)

Each type stores the statistic(s)/model(s) of choice along with sufficient statistics for updating.  

Every type contains the fields `n` (number of observations used) and `nb` (number of batches used), accessed via `n_obs(obj)` and `n_batches(obj)`, respectively.


### Updating objects with `update!`
```julia
	update!(obj, newdata)
```

### Joining objects with `update!`
```julia
	update!(obj1, obj2)
```
