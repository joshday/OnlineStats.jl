# Overview

This documentation is a work in progress.


`OnlineStats` is a Julia package which fits statistical models for online or streaming data.

### Weighting Schemes
The following schemes are supported for weighting new data:

- `EqualWeighting()`
- `ExponentialWeighting(λ)`, `ExponentialWeighting(n)`
- `StochasticWeighting(r)`
    - $λ = (\text{number of batches})^{-r}$

### Common Interface

- `state(o)`
    - state of the estimate as a vector
- `statenames(o)`
    - names corresponding to `state(o)`
- `update!(o, data...)`
- `updatebatch!(o, data...)`
- `onlinefit!(o, b, data...; batch = true)`
- `tracefit!(o, b, data...; batch = true)`
- `nobs(o)`
