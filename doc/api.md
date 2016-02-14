# API for OnlineStats

# Table of Contents
1. [BoundedExponentialWeight](#boundedexponentialweight)
1. [CompareTracePlot](#comparetraceplot)
1. [CovMatrix](#covmatrix)
1. [Diff](#diff)
1. [Diffs](#diffs)
1. [EqualWeight](#equalweight)
1. [ExponentialWeight](#exponentialweight)
1. [Extrema](#extrema)
1. [FitCategorical](#fitcategorical)
1. [HardThreshold](#hardthreshold)
1. [HyperLogLog](#hyperloglog)
1. [KMeans](#kmeans)
1. [LearningRate](#learningrate)
1. [LearningRate2](#learningrate2)
1. [LinReg](#linreg)
1. [Mean](#mean)
1. [Means](#means)
1. [Moments](#moments)
1. [NormalMix](#normalmix)
1. [QuantReg](#quantreg)
1. [QuantileMM](#quantilemm)
1. [QuantileSGD](#quantilesgd)
1. [StatLearn](#statlearn)
1. [StatLearnCV](#statlearncv)
1. [StatLearnSparse](#statlearnsparse)
1. [TracePlot](#traceplot)
1. [Variance](#variance)
1. [Variances](#variances)
1. [coefplot](#coefplot)
1. [fit!](#fit!)
1. [fitdistribution](#fitdistribution)
1. [sweep!](#sweep!)
1. [value](#value)

# BoundedExponentialWeight
`BoundedExponentialWeight(λ::Float64)`, `BoundedExponentialWeight(lookback::Int)`

Use equal weights until reaching λ = 2 / (1 + lookback), then hold constant.

# CompareTracePlot
Compare the values of multiple OnlineStats.  Useful for comparing competing models.

```julia
o1 = StatLearn(size(x, 2), SGD())
o2 = StatLearn(size(x, 2), AdaGrad())
tr = CompareTracePlot([o1, o2], o -> loss(o, x, y))
fit!(o1, x1, y1); fit!(o2, x1, y1)
fit!(o1, x2, y2); fit!(o2, x2, y2)
...
```

# CovMatrix
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

# Diff
Track the last value and the last difference.  Ignores `Weight`.

```julia
o = Diff()
o = Diff(y)
```

# Diffs
Track the last value and the last difference for multiple series.  Ignores `Weight`.

```julia
o = Diffs()
o = Diffs(y)
```

# EqualWeight
`EqualWeight()`.  All observations weighted equally.

# ExponentialWeight
`ExponentialWeight(λ::Float64)`, `ExponentialWeight(lookback::Int)`

Weights are held constant at λ = 2 / (1 + lookback).

# Extrema
Extrema (maximum and minimum).  Ignores `Weight`.

```julia
o = Extrema(y)
fit!(o, y2)
extrema(o)
```

# FitCategorical
Find the proportions for each unique input.  Categories are sorted by proportions. Ignores `Weight`.

```julia
o = FitCategorical(y)
```

# HardThreshold
After `burnin` observations, coefficients will be set to zero if they are less than `ϵ`.

# HyperLogLog
`HyperLogLog(b)`

Approximate count of distinct elements.  `HyperLogLog` differs from other OnlineStats in that any input to `fit!(o::HyperLogLog, input)` is considered a singleton.  Thus, a vector of inputs must be similar to:

```julia
o = HyperLogLog(4)
for yi in y
    fit!(o, yi)
end
```

# KMeans
Approximate K-Means clustering of multivariate data.

```julia
o = KMeans(y, 3, LearningRate())
value(o)
```

# LearningRate
`LearningRate(r = 0.6; minstep = 0.0)`.

Weight at update `t` is `1 / t ^ r`.  When weights reach `minstep`, hold weights constant.  Compare to `LearningRate2`.

# LearningRate2
LearningRate2(γ, c = 1.0; minstep = 0.0).

Weight at update `t` is `γ / (1 + γ * c * t)`.  When weights reach `minstep`, hold weights constant.  Compare to `LearningRate`.

# LinReg
Linear regression with optional regularization.

```julia
using  StatsBase
n, p = 100_000, 10
x = randn(n, p)
y = x * collect(1.:p) + randn(n)

o = LinReg(x, y)
coef(o)
predict(o, x)
confint(o, .95)
vcov(o)
stderr(o)
coeftable(o)
using Plots; coefplot(o)

# regularized estimates
coef(o, L2Penalty(.1))  # Ridge
coef(o, L1Penalty(.1))  # LASSO
coef(o, ElasticNetPenalty(.1, .5))
coef(o, SCADPenalty(.1, 3.7))
```

# Mean
Univariate mean.

```julia
o = Mean(y, EqualWeight())
o = Mean(y)
fit!(o, y2)
mean(o)
```

# Means
Means of multiple series, similar to `mean(x, 1)`.

```julia
o = Means(x, EqualWeight())
o = Means(x)
fit!(o, x2)
mean(o)
```

# Moments
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

# NormalMix
Normal Mixture of `k` components via an online EM algorithm.  `start` is a keyword argument specifying the initial parameters.

```julia
o = NormalMix(2, LearningRate(); start = MixtureModel(Normal, [(0, 1), (3, 1)]))
mean(o)
var(o)
std(o)
```

# QuantReg
Online MM Algorithm for Quantile Regression.

# QuantileMM
Approximate quantiles via an online MM algorithm.

```julia
o = QuantileMM(y, LearningRate())
o = QuantileMM(y, tau = [.25, .5, .75])
fit!(o, y2)
```

# QuantileSGD
Approximate quantiles via stochastic gradient descent.

```julia
o = QuantileSGD(y, LearningRate())
o = QuantileSGD(y, tau = [.25, .5, .75])
fit!(o, y2)
```

# StatLearn
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

# StatLearnCV
`StatLearnCV(o::StatLearn, xtest, ytest)`

Automatically tune the regularization parameter λ for `o` by minimizing loss on test data `xtest`, `ytest`.

# StatLearnSparse
### Enforce sparsity on a `StatLearn` object

`StatLearnSparse(o::StatLearn, s::AbstractSparsity)`

# TracePlot
`TracePlot(o::OnlineStat, f::Function = value)`

Create a trace plot using values from OnlineStat `o`.  Every call to `fit!(o, args...)` adds a new observation to the plot.

```julia
using Plots
o = Mean(ExponentialWeight(.1))
tr = TracePlot(o)
for i in 1:100
    fit!(tr, i / 100 + randn(100))
end

o = Variance()
tr = TracePlot(o, x -> [mean(o), var(o)])
for i in 1:100
    fit!(tr, randn(100))
end
```

# Variance
Univariate variance.

```julia
o = Variance(y, EqualWeight())
o = Variance(y)
fit!(o, y2)

mean(o)
var(o)
std(o)
```

# Variances
Variances of a multiple series, similar to `var(x, 1)`.

```julia
o = Variances(x, EqualWeight())
o = Variances(x)
fit!(o, x2)

mean(o)
var(o)
std(o)
```

# coefplot
For any OnlineStat that has a `coef` method, display a graphical representation of the coefficient vector.

```julia
using Plots
o = LinReg(x, y)
coefplot(o)
```

# fit!
`fit!(o::OnlineStat, y, b = 1)`

`fit!(o::OnlineStat, x, y, b = 1)`

Include more data for an OnlineStat using batch updates of size `b`.  Batch updates make more sense for OnlineStats that use stochastic approximation, such as `StatLearn`, `QuantileMM`, and `NormalMix`.

# fitdistribution
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

# sweep!
`sweep!(A, k, v, inv = false)`

Symmetric sweep of the matrix `A` on element `k` using vector `v` as storage to avoid memory allocation.  This requires `length(v) == size(A, 1)`.  Both `A` and `v` will be overwritten.

`inv = true` will perform an inverse sweep.  Only the upper triangle is read and swept.

`sweep!(A, k, inv = false)`

Symmetric sweep of the matrix `A` on element `k`.

# value
`value(o::OnlineStat)`.  The associated value of an OnlineStat.

for an OnlineStat using batch updates of size `b`.  Batch updates make more sense for OnlineStats that use stochastic approximation, such as `StatLearn`, `QuantileMM`, and `NormalMix`.

`fit!(o::OnlineStat, y, b = 1)`

`fit!(o::OnlineStat, x, y, b = 1)`

Include more data for an OnlineStat using batch updates of size `b`.  Batch updates make more sense for OnlineStats that use stochastic approximation, such as `StatLearn`, `QuantileMM`, and `NormalMix`.

`fit!(o::OnlineStat, y, b = 1)`

`fit!(o::OnlineStat, x, y, b = 1)`

Include more data for an OnlineStat using batch updates of size `b`.  Batch updates make more sense for OnlineStats that use stochastic approximation, such as `StatLearn`, `QuantileMM`, and `NormalMix`.

`fit!(o::OnlineStat, y, b = 1)`

`fit!(o::OnlineStat, x, y, b = 1)`

Include more data for an OnlineStat using batch updates of size `b`.  Batch updates make more sense for OnlineStats that use stochastic approximation, such as `StatLearn`, `QuantileMM`, and `NormalMix`.

# fitdistribution
Fit a distribution.

# sweep!
### `sweep!(A, k, v, inv = false)`

Symmetric sweep of the matrix `A` on element `k` using vector `v` as storage to avoid memory allocation.  This requires `length(v) == size(A, 1)`.  Both `A` and `v` will be overwritten.

`inv = true` will perform an inverse sweep.  Only the upper triangle is read and swept.

### `sweep!(A, k, inv = false)`

Symmetric sweep of the matrix `A` on element `k`.

# value
`value(o::OnlineStat)`.  The associated value of an OnlineStat.

