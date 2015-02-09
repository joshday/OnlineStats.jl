# OnlineStats

Online algorithms for statistics.  The driving function in this package is  

```update!(obj, newdata::Vector, addrow::Bool)```

- `newdata`: new Real, Vector, or DataArray  
- `addrow`: append row to results (`true`) or replace current estimates (`false`)


## Types 
Each type defined in OnlineStats contains the fields  

- `<<estimate>>`: Vector of saved estimates
- `n`: number of observations used  
- `nb`: number of batches used

Other fields will be used to store sufficient statistics for online updates.

Types currently implemented are:

- `Summary` 
  - Analytical estimates of mean, var, max, min
- `Quantile` 
  - Stochastic estimates of quantiles 
  - Two algorithms available: subgradient descent or MM

