<!--- Generated at 2016-06-15T22:17:50.  Don't edit --->
# API

## BernoulliBootstrap
`BernoulliBootstrap(o::OnlineStat, f::Function, r::Int = 1000)`

Create a double-or-nothing bootstrap using `r` replicates of `o` for estimate `f(o)`

Example:

```julia
BernoulliBootstrap(Mean(), mean, 1000)
```

## BiasMatrix
Adda bias/intercept term to a matrix on the fly without creating or copying data:

  * `BiasMatrix(rand(10,5))` is roughly equivalent to `hcat(rand(10,5), ones(10))`

## BiasVector
Add a bias/intercept term to a vector on the fly without creating or copying data:

  * `BiasVector(rand(10))` is roughly equivalent to `vcat(rand(10), 1.0)`

## BoundedEqualWeight
One of the `Weight` types.  Uses `EqualWeight` until reaching `λ = 2 / (1 + lookback)`, then weights are held constant.

  * `BoundedEqualWeight(λ::Float64)`
  * `BoundedEqualWeight(lookback::Int)`

## CovMatrix
Covariance matrix, similar to `cov(x)`.

```julia
o = CovMatrix(x, EqualWeight())
o = CovMatrix(x)
fit!(o, x2)

cor(o)
cov(o)
mean(o)
var(o)
```

## Diff
Track the last value and the last difference.

```julia
o = Diff()
o = Diff(y)
```

## Diffs
Track the last value and the last difference for multiple series.  Ignores `Weight`.

```julia
o = Diffs()
o = Diffs(y)
```

## EqualWeight
One of the `Weight` types.  Observations are weighted equally.  For analytical updates, the online algorithm will give results equal to the offline version.

  * `EqualWeight()`

## ExponentialWeight
One of the `Weight` types.  Updates are performed with a constant weight `λ = 2 / (1 + lookback)`.

  * `ExponentialWeight(λ::Float64)`
  * `ExponentialWeight(lookback::Int)`

## Extrema
Extrema (maximum and minimum).

```julia
o = Extrema(y)
fit!(o, y2)
extrema(o)
```

## FitCategorical
Find the proportions for each unique input.  Categories are sorted by proportions. Ignores `Weight`.

```julia
o = FitCategorical(y)
```

## HyperLogLog
`HyperLogLog(b)`

Approximate count of distinct elements.  `HyperLogLog` differs from other OnlineStats in that any input to `fit!(o::HyperLogLog, input)` is considered a singleton.  Thus, a vector of inputs must be done by:

```julia
o = HyperLogLog(4)
for yi in y
    fit!(o, yi)
end
```

## KMeans
Approximate K-Means clustering of multivariate data.

```julia
o = KMeans(y, 3, LearningRate())
value(o)
```

## LearningRate
One of the `Weight` types.  It's primary use is for the OnlineStats that use stochastic approximation (`StatLearn`, `QuantReg`, `QuantileMM`, `QuantileSGD`, `NormalMix`, and `KMeans`).  The weight at update `t` is `1 / t ^ r`.  When weights reach `λ`, they are held consant.  Compare to `LearningRate2`.

  * `LearningRate(r = 0.5, λ = 0.0)`

## LearningRate2
One of the `Weight` types.  It's primary use is for the OnlineStats that use stochastic approximation (`StatLearn`, `QuantReg`, `QuantileMM`, `QuantileSGD`, `NormalMix`, and `KMeans`).  The weight at update `t` is `1 / (1 + c * (t - 1))`.  When weights reach `λ`, they are held consant.  Compare to `LearningRate`.

  * `LearningRate2(c = 0.5, λ = 0.0)`

## LinReg
Analytical Linear Regression.

With `EqualWeight`, this is equivalent to offline linear regression.

```
using OnlineStats, StatsBase
o = LinReg(x, y, wgt = EqualWeight())
coef(o)
coeftable(o)
vcov(o)
stderr(o)
predict(o, x)
confint(o, .95)
```

## Mean
Mean of a single series.

```julia
y = randn(100)

o = Mean()
fit!(o, y)

o = Mean(y)
```

## Means
Means of multiple series, similar to `mean(x, 1)`.

```julia
x = randn(1000, 5)
o = Means(5)
fit!(o, x)
mean(o)
```

## Moments
Univariate, first four moments.  Provides `mean`, `var`, `skewness`, `kurtosis`

```julia
o = Moments(x, EqualWeight())
o = Moments(x)
fit!(o, x2)

mean(o)
var(o)
std(o)
StatsBase.skewness(o)
StatsBase.kurtosis(o)
```

## NormalMix
Normal Mixture of `k` components via an online EM algorithm.  `start` is a keyword argument specifying the initial parameters.

```julia
o = NormalMix(2, LearningRate(); start = MixtureModel(Normal, [(0, 1), (3, 1)]))
mean(o)
var(o)
std(o)
```

## QuantReg
Online MM Algorithm for Quantile Regression.

## QuantileMM
Approximate quantiles via an online MM algorithm.  Typically more accurate than `QuantileSGD`.

```julia
o = QuantileMM(y, LearningRate())
o = QuantileMM(y, tau = [.25, .5, .75])
fit!(o, y2)
```

## QuantileSGD
Approximate quantiles via stochastic gradient descent.

```julia
o = QuantileSGD(y, LearningRate())
o = QuantileSGD(y, tau = [.25, .5, .75])
fit!(o, y2)
```

## StatLearn
Online statistical learning algorithms.

  * `StatLearn(p)`
  * `StatLearn(x, y)`
  * `StatLearn(x, y, b)`

The model is defined by:

#### `ModelDefinition`

  * `L2Regression()`     - Squared error loss.  Default.
  * `L1Regression()`     - Absolute loss
  * `LogisticRegression()`     - Model for data in {0, 1}
  * `PoissonRegression()`     - Model count data {0, 1, 2, 3, ...}
  * `QuantileRegression(τ)`     - Model conditional quantiles
  * `SVMLike()`     - For data in {-1, 1}.  Perceptron with `NoPenalty`. SVM with `RidgePenalty`.
  * `HuberRegression(δ)`     - Robust Huber loss

#### `Penalty`

  * `NoPenalty()`     - No penalty.  Default.
  * `RidgePenalty(λ)`     - Ridge regularization: `dot(β, β)`
  * `LassoPenalty(λ)`     - Lasso regularization: `sumabs(β)`
  * `ElasticNetPenalty(λ, α)`     - Ridge/LASSO weighted average.  `α = 0` is Ridge, `α = 1` is LASSO.
  * `SCADPenalty(λ, a = 3.7)`     - Smoothly clipped absolute deviation penalty.  Essentially LASSO with less bias     for larger coefficients.

#### `Algorithm`

  * `SGD()`     - Stochastic gradient descent.  Default.
  * `AdaGrad()`     - Adaptive gradient method. Ignores `Weight`.
  * `AdaDelta()`     - Extension of AdaGrad.  Ignores `Weight`.
  * `RDA()`     - Regularized dual averaging with ADAGRAD.  Ignores `Weight`.
  * `MMGrad()`     - Experimental online MM gradient method.

**Note:** The order of the `ModelDefinition`, `Penalty`, and `Algorithm` arguments don't matter.

```julia
StatLearn(x, y)
StatLearn(x, y, AdaGrad())
StatLearn(x, y, MMGrad(), LearningRate(.5))
StatLearn(x, y, 10, LearningRate(.7), RDA(), SVMLike(), RidgePenalty(.1))
```

## Sum
Track the running sum.  Ignores `Weight`.

```julia
o = Sum()
o = Sum(y)
```

## Sums
Track the running sum for multiple series.  Ignores `Weight`.

```julia
o = Sums()
o = Sums(y)
```

## TwoWayInteractionMatrix
Add second-order interaction terms on the fly without creating or copying data:

  * `TwoWayInteractionMatrix(rand(n, p))` "adds" the `binomial(p, 2)` interaction terms to each row

## TwoWayInteractionVector
Add second-order interaction terms on the fly without creating or copying data:

  * `TwoWayInteractionVector(rand(p))` "adds" the `binomial(p, 2)` interaction terms

## Variance
Univariate variance.

```julia
y = randn(100)
o = Variance(y)
mean(o)
var(o)
std(o)
```

## Variances
Variances of a multiple series, similar to `var(x, 1)`.

```julia
o = Variances(x, EqualWeight())
o = Variances(x)
fit!(o, x2)

mean(o)
var(o)
std(o)
```

## fit!
Update an OnlineStat with more data.  Additional arguments after the input data provide extra control over how the updates are done.

```
y = randn(100)
o = Mean()

fit!(o, y)      # standard usage

fit!(o, y, 10)  # update in minibatches of size 10

fit!(o, y, .1)  # update using weight .1 for each observation

wts = rand(100)
fit!(o, y, wts) # update observation i using wts[i]
```

Update an OnlineStat with more data.  Additional arguments after the input data provide extra control over how the updates are done.

```
y = randn(100)
o = Mean()

fit!(o, y)      # standard usage

fit!(o, y, 10)  # update in minibatches of size 10

fit!(o, y, .1)  # update using weight .1 for each observation

wts = rand(100)
fit!(o, y, wts) # update observation i using wts[i]
```

Update an OnlineStat with more data.  Additional arguments after the input data provide extra control over how the updates are done.

```
y = randn(100)
o = Mean()

fit!(o, y)      # standard usage

fit!(o, y, 10)  # update in minibatches of size 10

fit!(o, y, .1)  # update using weight .1 for each observation

wts = rand(100)
fit!(o, y, wts) # update observation i using wts[i]
```

## fitdistribution
Estimate the parameters of a distribution.

```julia
using Distributions
# Univariate distributions
o = fitdistribution(Beta, y)
o = fitdistribution(Categorical, y)  # ignores Weight
o = fitdistribution(Cauchy, y)
o = fitdistribution(Gamma, y)
o = fitdistribution(LogNormal, y)
o = fitdistribution(Normal, y)
mean(o)
var(o)
std(o)
params(o)

# Multivariate distributions
o = fitdistribution(Multinomial, x)
o = fitdistribution(MvNormal, x)
mean(o)
var(o)
std(o)
cov(o)
```

## maprows
Perform operations on data in blocks.

`maprows(f::Function, b::Integer, data...)`

This function iteratively feeds `data` in blocks of `b` observations to the function `f`.  The most common usage is with `do` blocks:

```julia
# Example 1
y = randn(50)
o = Variance()
maprows(10, y) do yi
    fit!(o, yi)
    println("Updated with another batch!")
end
```

## nobs
nobs(obj::StatisticalModel)

Returns the number of independent observations on which the model was fitted. Be careful when using this information, as the definition of an independent observation may vary depending on the model, on the format used to pass the data, on the sampling plan (if specified), etc.

## sweep!
`sweep!(A, k, inv = false)`, `sweep!(A, k, v, inv = false)`

Symmetric sweep operator of the matrix `A` on element `k`.  `A` is overwritten. `inv = true` will perform the inverse sweep.  Only the upper triangle is read and swept.

An optional vector `v` can be provided to avoid memory allocation. This requires `length(v) == size(A, 1)`.  Both `A` and `v` will be overwritten.

```julia
x = randn(100, 10)
xtx = x'x
sweep!(xtx, 1)
sweep!(xtx, 1, true)
```

## value
The associated value of an OnlineStat.

```
o = Mean()
value(o)
```

