# Introduction

**OnlineStats** is a [Julia](http://julialang.org) package which provides online algorithms for statistical models.  Observations are processed one at a time and all **algorithms use O(1) memory**.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  For machine learning (predictive modeling) applications, online algorithms provide fast approximate solutions to vastly reduce training time.  However, many of the algorithms provide exact analytical solutions.

# Overview

<h3>Every OnlineStat is a type</h3>

Two general ways of creating objects:    

1. Create "empty" object and add data
1. Create object with data

```julia
o = Mean()
update!(o, rand(100))

o = Mean(rand(100))
```

<h3>All OnlineStats can be updated</h3>
```julia
o = Variance(randn(100))
update!(o, randn(123))
nobs(o)  # Number of observations = 223
```


<h3>Common Interface</h3>


| function                                   | Description                                                                        | Return               |
|:-------------------------------------------|:-----------------------------------------------------------------------------------|:---------------------|
| `state(o)`                                 | State of the estimate                                                              | `Vector{Any}`        |
| `statenames(o)`                            | Names corresponding to `state(o)`                                                  | `Vector{Symbol}`     |
| `nobs(o)`                                  | number of observations                                                             | `Int`                |
| `update!(o, data...)`                      | Update model with respect to the weighting scheme                                  |                      |
| `updatebatch!(o, data...)`                 | Minibatch update.  Available only for models that benefit from minibatch updates   |                      |
| `onlinefit!(o, b, data...; batch = false)` | update `o` with batches of size `b`.  `batch = false`  calls `update!(o, data...)` |                      |
| `tracefit!(o, b, data...; batch = false)`  | call `onlinefit!` and save historical objects at every `b` observations            | `Vector{OnlineStat}` |
| `traceplot!(o, b, data...)`                | call `onlinefit!` and create a trace plot of the estimate                          |                      |


# Weighting Schemes
```julia
o = Mean(x, ExponentialWeighting(1000))
```

When creating an OnlineStat, one can specify the weighting to be used (with the exception of `SGModel`, which has its own weighting system).  Updating a model typically involves one of two forms:

- weighted average (equivalent forms shown below):

$$\theta^{(t+1)} = (1 - \gamma_t)\theta^{(t)} + \gamma_t \theta_{\text{new}}$$
$$\theta^{(t+1)} = \theta^{(t)} + \gamma_t(\theta_{\text{new}} - \theta^{(t)})$$

- stochastic gradient-based:  

$$\theta^{(t+1)} = \theta^{(t)} - \gamma_t g_{t+1}$$

The following schemes are supported for determining weights:

<h3>Equal Weighting</h3>
- `EqualWeighting()`

Each piece of data is weighted equally.

<h3>Exponential Weighting</h3>
- `ExponentialWeighting(λ::Float64)`
- `ExponentialWeighting(n::Int64)`

Use equal weighting until the step size reaches `λ = 1/n`, then hold constant.

<h3>Learning Rate</h3>
- `LearningRate(;r::Float64 = 1.0, λ::Float64 = 1.0, minstep::Float64 = 0.0)`

For the `t`-th update, use weight $γ_t = \frac{1}{1 + \lambda t^r}, r\in (.5, 1], \lambda > 0$, until weights reach `minstep`, then hold constant.  This is typically used for stochastic gradient-based methods or online EM/MM algorithms.  An `r` closer to 1 makes step sizes decay faster, resulting in slower-moving estimates.


![](images/learningrate_rs.png)

# What OnlineStats Can Do

<h3> Summary Statistics </h3>
|                       |                                                                                      |
|:----------------------|:-------------------------------------------------------------------------------------|
| five number summary   | `FiveNumberSummary`                                                                  |
| maximum/minimum       | `Extrema`                                                                            |
| mean                  | `Mean`, `Means`                                                                      |
| quantiles             | `QuantileMM`, `QuantileSGD`                                                          |
| skewness and kurtosis | `Moments`                                                                            |
| variance              | `Variance`, `Variances`, bootstrapping with `BernoulliBootstrap`, `PoissonBootstrap` |


<h3> Linear Models and Predictive Modeling </h3>

|                                   |                              |
|:----------------------------------|:-----------------------------|
| L1 Regression                     | `SGModel`                    |
| linear regression                 | `LinReg`, `SGModel`          |
| logistic regression               | `SGModel`, `LogRegSGD2`      |
| poisson regression                | `SGModel`                    |
| quantile regression               | `QuantRegMM`, `SGModel`      |
| regression w/ LASSO penalty       | `SparseReg`, `SGModel`       |
| regression w/ ridge penalty       | `SparseReg`, `SGModel`       |
| regression w/ elastic net penalty | `SparseReg`, `SGModel`       |
| regression w/ SCAD penalty        | `SparseReg`, `SGModel`       |
| self-tuning models                | `SGModelCV`                  |
| stepwise regression               | `StepwiseReg` (experimental) |
| support vector machine            | `SGModel`                    |


<h3> Multivariate Analysis </h3>
|                               |                                         |
|:------------------------------|:----------------------------------------|
| covariance matrix             | `CovarianceMatrix`                      |
| principal components analysis | `OnlinePCA`, `pca(o::CovarianceMatrix)` |
| partial least squares         | `OnlinePLS`                             |


<h3> Parametric Density Estimation </h3>
For nonparametric density estimation, see [AverageShiftedHistograms.jl](https://github.com/joshday/AverageShiftedHistograms.jl)

|                     |                  |
|:--------------------|:-----------------|
| bernoulli           | `FitBernoulli`   |
| beta                | `FitBeta`        |
| binomial            | `FitBinomial`    |
| cauchy              | `FitCauchy`      |
| exponential         | `FitExponential` |
| gamma               | `FitGamma`       |
| lognormal           | `FitLogNormal`   |
| multinomial         | `FitMultinomial` |
| multivariate normal | `FitMvNormal`    |
| normal              | `FitNormal`      |
| normal mixture      | `NormalMix`      |
| poisson             | `FitPoisson`     |
