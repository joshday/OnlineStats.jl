# Overview

This documentation is a work in progress.


`OnlineStats` is a Julia package which fits statistical models for online or streaming data.

### Weighting Schemes
When creating an OnlineStat, one can optionally specify the weighting to be used (with the exception of `Adagrad`).  Updating a statistic or model involves one of two forms:

- weighted average: `λ * some_update + (1 - λ) * current_value`
- gradient-based:  `current_value -= λ * estimated_gradient`

The following schemes are supported for determining weights:

- `EqualWeighting()`
    - each piece of data is weighted equally.
- `ExponentialWeighting(λ::Float64)`
    - Use equal weighting until the step size reaches λ, then hold constant.
- `ExponentialWeighting(n::Int64)`
    - Use equal weighting until step sizes reaches `1/n`, then hold constant
- `StochasticWeighting(r)`
    - Use weight `number_of_updates ^ -r` where `r` is greater than .5 and less than or equal to 1.  This is typically used for stochastic gradient-based methods or online EM/MM algorithms.




### Common Interface

- `state(o)`
    - state of the estimate as a vector
- `statenames(o)`
    - names corresponding to `state(o)`
- `update!(o, data...)`
    - update observations one at a time with respect to the weighting scheme
- `updatebatch!(o, data...)`
    - treat a batch of data as an equal piece of information.  The weighting scheme is applied uniformly to all data in the batch.
- `onlinefit!(o, b, data...; batch = false)`
    - update `o` with batches of size `b`.  `batch = false` defaults to `update!(o, data...)`
- `tracefit!(o, b, data...; batch = false)`
    - Run through data as in `onlinefit` and return a vector `OnlineStat[o1, o2,...]` where each element
    has been updated with a batch of size `b`.
- `nobs(o)`
    - number of observations
