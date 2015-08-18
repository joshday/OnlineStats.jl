# Overview

`OnlineStats` is a Julia package which fits statistical models for online or streaming data.

### Weighting Schemes
When creating an OnlineStat, one can optionally specify the weighting to be used (with the exception of `Adagrad`, which aims to remove the necessity of choosing hyperparameters).  Updating a statistic or model involves one of two forms:

- weighted average: `λ * newval + (1 - λ) * θ`, or equivalently `θ + λ * (newval - θ)`
- gradient-based:  `θ - λ * gradient`

The following schemes are supported for determining weights:

- `EqualWeighting()`
    - each piece of data is weighted equally.
- `ExponentialWeighting(λ::Float64)`
    - Use equal weighting until the step size reaches λ, then hold constant.
- `ExponentialWeighting(n::Int64)`
    - Use equal weighting until step sizes reaches `1/n`, then hold constant
- `StochasticWeighting(r::Float64)`
    - Use weight `number_of_updates ^ -r` where `r` is greater than .5 and less than or equal to 1.  This is typically used for stochastic gradient-based methods or online EM/MM algorithms.




### Common Interface

- `state(o)`
    - state of the estimate as a vector
- `statenames(o)`
    - names corresponding to `state(o)`
- `update!(o, data...)`
    - update observations one at a time with respect to the weighting scheme
- `updatebatch!(o, data...)`
    - treat a batch of data as an equal piece of information.  A gradient-based update uses the entire batch to estimate the gradient and one step is taken.  
- `onlinefit!(o, b, data...; batch = false)`
    - update `o` with batches of size `b`.  `batch = false` simply calls `update!(o, data...)`
- `tracefit!(o, b, data...; batch = false)`
    - Run through data as in `onlinefit` and return a vector `OnlineStat[o1, o2,...]` where each element
    has been updated with a batch of size `b`.
- `nobs(o)`
    - number of observations
