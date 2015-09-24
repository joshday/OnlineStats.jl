# Description

**OnlineStats** is a Julia package which provides online algorithms for statistical models.  Observations are processed one at a time and all **algorithms use O(1) memory**.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  For machine learning (predictive modeling) applications, online algorithms provide fast approximate solutions for when training time is a bottleneck.

# Getting Started

<h3>Every statistic/model is a type</h3>

Two general ways of creating objects:    

1. Create "empty" object and add data
1. Create object with data

```julia
o = Mean()
update!(o, rand(100))

o = Mean(rand(100))
```

<h3>All models can be updated</h3>
```julia
o = Variance(randn(100))
update!(o, randn(123))
nobs(o)  # Number of observations = 223
```


<h3>Models use a  Common Interface</h3>


| method                                     | Description                                                                        | Return               |
|:-------------------------------------------|:-----------------------------------------------------------------------------------|:---------------------|
| `state(o)`                                 | State of the estimate                                                              | `Vector{Any}`        |
| `statenames(o)`                            | Names corresponding to `state(o)`                                                  | `Vector{Symbol}`     |
| `nobs(o)`                                  | number of observations                                                             | `Int`                |
| `update!(o, data...)`                      | Update model with respect to the weighting scheme                                  |                      |
| `updatebatch!(o, data...)`                 | Minibatch update.  Available for types that benefit from minibatch updates         |                      |
| `onlinefit!(o, b, data...; batch = false)` | update `o` with batches of size `b`.  `batch = false`  calls `update!(o, data...)` |                      |
| `tracefit!(o, b, data...; batch = false)`  | call `onlinefit` and save historical objects at every `b` observations             | `Vector{OnlineStat}` |
| `traceplot!(o, b, data...)`                | call `onlinefit` and create a trace plot of the estimate                           |                      |


# Weighting Schemes
When creating an OnlineStat, one can specify the weighting to be used (with the exception of `SGModel`, which has its own weighting system.  Updating a model typically involves one of two forms:

- weighted average (equivalent forms shown below):

$$\theta^{(t+1)} = (1 - \gamma)\theta^{(t)} + \gamma \theta_{\text{new}}$$
$$\theta^{(t+1)} = \theta^{(t)} + \gamma(\theta_{\text{new}} - \theta^{(t)})$$

- stochastic gradient-based:  

$$\theta^{(t+1)} = \theta^{(t)} - \gamma g_{t+1}$$

The following schemes are supported for determining weights:

<h3>Equal Weighting</h3>
- `EqualWeighting()`

Each piece of data is weighted equally.

<h3>Exponential Weighting</h3>
- `ExponentialWeighting(λ::Float64)`
- `ExponentialWeighting(n::Int64)`

Use equal weighting until the step size reaches `λ = 1/n`, then hold constant.

<h3>Stochastic Weighting</h3>
- `StochasticWeighting(r::Float64)`

Use weight `γ = number_of_updates ^ -r` where `r` $\in (.5, 1]$.  This is typically used for stochastic gradient-based methods or online EM/MM algorithms.  An `r` closer to 1 makes step sizes decay faster, resulting in slower-moving estimates.
