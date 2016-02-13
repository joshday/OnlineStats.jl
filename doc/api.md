# API for OnlineStats

---
## Table of Contents1. [BernoulliBootstrap](#BernoulliBootstrap)
1. [BoundedExponentialWeight](#BoundedExponentialWeight)
1. [CovMatrix](#CovMatrix)
1. [Diff](#Diff)
1. [Diffs](#Diffs)
1. [EqualWeight](#EqualWeight)
1. [ExponentialWeight](#ExponentialWeight)
1. [Extrema](#Extrema)
1. [FitCategorical](#FitCategorical)
1. [FrozenBootstrap](#FrozenBootstrap)
1. [HardThreshold](#HardThreshold)
1. [HyperLogLog](#HyperLogLog)
1. [LearningRate](#LearningRate)
1. [LearningRate2](#LearningRate2)
1. [Mean](#Mean)
1. [Means](#Means)
1. [Moments](#Moments)
1. [NormalMix](#NormalMix)
1. [PoissonBootstrap](#PoissonBootstrap)
1. [QuantReg](#QuantReg)
1. [QuantileMM](#QuantileMM)
1. [QuantileSGD](#QuantileSGD)
1. [StatLearn](#StatLearn)
1. [StatLearnCV](#StatLearnCV)
1. [StatLearnSparse](#StatLearnSparse)
1. [Variance](#Variance)
1. [Variances](#Variances)
1. [cached_state](#cached_state)
1. [fit!](#fit!)
1. [replicates](#replicates)
1. [sweep!](#sweep!)
1. [value](#value)
### BernoulliBootstrap
`BernoulliBootstrap(o, f, r)`

Create a double-or-nothing bootstrap using `r` replicates of OnlineStat `o` for estimate `f(o)`

Example: `BernoulliBootstrap(Mean(), mean, 1000)`

### BoundedExponentialWeight
`BoundedExponentialWeight(minstep)`.  Once equal weights reach `minstep`, hold weights constant.

### CovMatrix
Covariance matrix

### Diff
Track the last value and the last difference

### Diffs
Track the last values and the last differences for multiple series

### EqualWeight
All observations weighted equally.

### ExponentialWeight
`ExponentialWeight(λ)`.  Most recent observation has a constant weight of λ.

### Extrema
Extrema (maximum and minimum).  Ignores `Weight`.

### FitCategorical
`FitCategorical(y)`

Find the proportions for each unique input.  Categories are sorted by proportions.

### FrozenBootstrap
Frozen bootstrap object are generated when two bootstrap distributions are combined, e.g., if they are differenced.

### HardThreshold
After `burnin` observations, coefficients will be set to zero if they are less than `ϵ`.

### HyperLogLog
`HyperLogLog(b)`

Approximate count of distinct elements.  `HyperLogLog` differs from other OnlineStats in that any input to `fit!(o::HyperLogLog, input)` is considered a singleton.  Thus, a vector of inputs must be similar to:

```julia
o = HyperLogLog(4)
for yi in y
    fit!(o, yi)
end
```

### LearningRate
`LearningRate(r; minstep = 0.0)`.

Weight at update `t` is `1 / t ^ r`.  Compare to `LearningRate2`.

### LearningRate2
LearningRate2(γ, c = 1.0; minstep = 0.0).

Weight at update `t` is `γ / (1 + γ * c * t)`.  Compare to `LearningRate`.

### Mean
Univariate Mean

### Means
Mean vector of a data matrix, similar to `mean(x, 1)`

### Moments
Univariate, first four moments.  Provides `mean`, `var`, `skewness`, `kurtosis`

### NormalMix
`NormalMix(k, wgt; start)`

Normal Mixture of `k` components via an online EM algorithm.  `start` is a keyword argument specifying the initial parameters.

If the algorithm diverges, try using a different `start`.

Example:

`NormalMix(k, wgt; start = MixtureModel(Normal, [(0, 1), (3, 1)]))`

### PoissonBootstrap
`PoissonBootstrap(o, f, r)`

Create a poisson bootstrap using `r` replicates of OnlineStat `o` for estimate `f(o)`

Example: `PoissonBootstrap(Mean(), mean, 1000)`

### QuantReg
Online MM Algorithm for Quantile Regression.

### QuantileMM
Approximate quantiles via an online MM algorithm

### QuantileSGD
Approximate quantiles via stochastic gradient descent

### StatLearn
### Online Statistical Learning

  * `StatLearn(p)`
  * `StatLearn(x, y)`
  * `StatLearn(x, y, b)`

The model is defined by:

#### `ModelDef`

  * `L2Regression()`     - Squared error loss.  Default.
  * `L1Regression()`     - Absolute loss
  * `LogisticRegression()`     - Model for data in {0, 1}
  * `PoissonRegression()`     - Model count data {0, 1, 2, 3, ...}
  * `QuantileRegression(τ)`     - Model conditional quantiles
  * `SVMLike()`     - Perceptron with `NoPenalty`. SVM with `L2Penalty`.
  * `HuberRegression(δ)`     - Robust Huber loss

#### `Penalty`

  * `NoPenalty()`     - No penalty.  Default.
  * `L2Penalty(λ)`     - Ridge regularization
  * `L1Penalty(λ)`     - LASSO regularization
  * `ElasticNetPenalty(λ, α)`     - Ridge/LASSO weighted average.  `α = 0` is Ridge, `α = 1` is LASSO.

#### `Algorithm`

  * `SGD()`     - Stochastic gradient descent.  Default.
  * `AdaGrad()`     - Adaptive gradient method. Ignores `Weight`.
  * `AdaDelta()`     - Extension of AdaGrad.  Ignores `Weight`.
  * `RDA()`     - Regularized dual averaging with ADAGRAD.  Ignores `Weight`.
  * `MMGrad()`     - Experimental online MM gradient method.
  * `AdaMMGrad()`     - Experimental adaptive online MM gradient method.  Ignores `Weight`.

### Example:

`StatLearn(x, y, 10, LearningRate(.7), RDA(), SVMLike(), L2Penalty(.1))`

### StatLearnCV
`StatLearnCV(o::StatLearn, xtest, ytest)`

Automatically tune the regularization parameter λ for `o` by minimizing loss on test data `xtest`, `ytest`.

### StatLearnSparse
### Enforce sparsity on a `StatLearn` object

`StatLearnSparse(o::StatLearn, s::AbstractSparsity)`

### Variance
Univariate Variance

### Variances
Variance vector of a data matrix, similar to `var(x, 1)`

### cached_state
Return the value of interest for each of the `OnlineStat` replicates

### fit!
`fit!(o::OnlineStat, y, b = 1)`

`fit!(o::OnlineStat, x, y, b = 1)`

Include more data for an OnlineStat using batch updates of size `b`.  Batch updates make more sense for OnlineStats that use stochastic approximation, such as `StatLearn`, `QuantileMM`, and `NormalMix`.

### replicates
Get the replicates of the `OnlineStat` objects used in the bootstrap

### sweep!
### `sweep!(A, k, v, inv = false)`

Symmetric sweep of the matrix `A` on element `k` using vector `v` as storage to avoid memory allocation.  This requires `length(v) == size(A, 1)`.  Both `A` and `v` will be overwritten.

`inv = true` will perform an inverse sweep.  Only the upper triangle is read and swept.

### `sweep!(A, k, inv = false)`

Symmetric sweep of the matrix `A` on element `k`.

### value
`value(o::OnlineStat)`.  The associated value of an OnlineStat.

