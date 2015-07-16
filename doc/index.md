# Overview

This documentation is a work in progress.


`OnlineStats` is a Julia package which fits statistical models for online or streaming data.

### Weighting Schemes
The following schemes are supported for weighting new data:

- `EqualWeighting()`
- `ExponentialWeighting(λ)`, `ExponentialWeighting(n)`
- `StochasticWeighting(r)`


### Common Interface

- `state(o)`
    - state of the estimate as a vector
- `statenames(o)`
    - names corresponding to `state(o)`
- `update!(o, data...)`
    - update observations one at a time with respect to the weighting scheme
- `updatebatch!(o, data...)`
    - treat a batch of data as "equally-weighted information".  The weighting scheme
- `onlinefit!(o, b, data...; batch = false)`
    - update `o` with batches of size `b`.  `batch = false` defaults to `update!(o, data...)`
- `tracefit!(o, b, data...; batch = false)`
    - Run through data as in `onlinefit` and return a vector `OnlineStat[o1, o2,...]` where each element
    has been updated with a batch of size `b`.
- `nobs(o)`
    - number of observations
