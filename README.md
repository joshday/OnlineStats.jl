# OnlineStats

Online algorithms for statistics.  The driving function in this package is  

```update!(obj, newdata::Vector, addrow::Bool)```

where obj has one of the following types:  

- `Summary` 
  - Analytical estimates mean, var, max, min
  - Stochastic estimates of specified quantiles (subgradient descent or MM)
- `Quantile` 
  - Stochastic estimates of quantiles 
  - subgradient descent or MM

`newdata` is the vector of new observations.  

`addrow` is whether the new update should replace the previous update (`false`) or a new row should be added (`true`)

-----

Each `obj` will store estimates (with the form `obj.estimate`), any necessary sufficient statistics for the update, and:   
- `obj.n`: Number of observations used  
- `obj.nb`: Number of Batches