<!--- This file was generated at 2016-04-14T14:32:11.  Do not edit by hand --->
# API for OnlineStats

# Table of Contents

- [<pre>BernoulliBootstrap                                      Bootstrap{ScalarInput}</pre>](#bernoullibootstrap)
- [<pre>BoundedEqualWeight                                      Weight</pre>](#boundedequalweight)
- [<pre>CovMatrix                                               OnlineStat{VectorInput}</pre>](#covmatrix)
- [<pre>Diff                                                    OnlineStat{ScalarInput}</pre>](#diff)
- [<pre>Diffs                                                   OnlineStat{VectorInput}</pre>](#diffs)
- [<pre>EqualWeight                                             BatchWeight</pre>](#equalweight)
- [<pre>ExponentialWeight                                       Weight</pre>](#exponentialweight)
- [<pre>Extrema                                                 OnlineStat{ScalarInput}</pre>](#extrema)
- [<pre>FitCategorical                                          DistributionStat{ScalarInput}</pre>](#fitcategorical)
- [<pre>HyperLogLog                                             OnlineStat{I<:Input}</pre>](#hyperloglog)
- [<pre>KMeans                                                  OnlineStat{VectorInput}</pre>](#kmeans)
- [<pre>LearningRate                                            StochasticWeight</pre>](#learningrate)
- [<pre>LearningRate2                                           StochasticWeight</pre>](#learningrate2)
- [<pre>LinReg                                                  OnlineStat{XYInput}</pre>](#linreg)
- [<pre>Mean                                                    OnlineStat{ScalarInput}</pre>](#mean)
- [<pre>Means                                                   OnlineStat{VectorInput}</pre>](#means)
- [<pre>Moments                                                 OnlineStat{ScalarInput}</pre>](#moments)
- [<pre>NormalMix                                               DistributionStat{ScalarInput}</pre>](#normalmix)
- [<pre>QuantReg                                                OnlineStat{XYInput}</pre>](#quantreg)
- [<pre>QuantileMM                                              OnlineStat{ScalarInput}</pre>](#quantilemm)
- [<pre>QuantileSGD                                             OnlineStat{ScalarInput}</pre>](#quantilesgd)
- [<pre>StatLearn                                               OnlineStat{XYInput}</pre>](#statlearn)
- [<pre>StatLearnCV                                             OnlineStat{XYInput}</pre>](#statlearncv)
- [<pre>StatLearnSparse                                         OnlineStat{XYInput}</pre>](#statlearnsparse)
- [<pre>Sum                                                     OnlineStat{ScalarInput}</pre>](#sum)
- [<pre>Sums                                                    OnlineStat{VectorInput}</pre>](#sums)
- [<pre>Variance                                                OnlineStat{ScalarInput}</pre>](#variance)
- [<pre>Variances                                               OnlineStat{VectorInput}</pre>](#variances)
- [<pre>fit!                                                    Function</pre>](#fit!)
- [<pre>fitdistribution                                         Function</pre>](#fitdistribution)
- [<pre>nobs                                                    Function</pre>](#nobs)
- [<pre>sweep!                                                  Function</pre>](#sweep!)
- [<pre>value                                                   Function</pre>](#value)

# BernoulliBootstrap
`BernoulliBootstrap(o::OnlineStat, f::Function, r::Int = 1000)`

Create a double-or-nothing bootstrap using `r` replicates of `o` for estimate `f(o)`

Example:

```julia
BernoulliBootstrap(Mean(), mean, 1000)
```

[Top](#table-of-contents)
# BoundedEqualWeight
`BoundedEqualWeight(λ::Float64)`, `BoundedEqualWeight(lookback::Int)`

Use equal weights until reaching `λ = 2 / (1 + lookback)`, then hold constant.

[Top](#table-of-contents)
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

[Top](#table-of-contents)
# Diff
Track the last value and the last difference.

```julia
o = Diff()
o = Diff(y)
```

[Top](#table-of-contents)
# Diffs
Track the last value and the last difference for multiple series.  Ignores `Weight`.

```julia
o = Diffs()
o = Diffs(y)
```

[Top](#table-of-contents)
# EqualWeight
`EqualWeight()`.  All observations weighted equally.

[Top](#table-of-contents)
# ExponentialWeight
`ExponentialWeight(λ::Float64)`, `ExponentialWeight(lookback::Int)`

Weights are held constant at `λ = 2 / (1 + lookback)`.

[Top](#table-of-contents)
# Extrema
Extrema (maximum and minimum).

```julia
o = Extrema(y)
fit!(o, y2)
extrema(o)
```

[Top](#table-of-contents)
# FitCategorical
Find the proportions for each unique input.  Categories are sorted by proportions. Ignores `Weight`.

```julia
o = FitCategorical(y)
```

[Top](#table-of-contents)
# HyperLogLog
`HyperLogLog(b)`

Approximate count of distinct elements.  `HyperLogLog` differs from other OnlineStats in that any input to `fit!(o::HyperLogLog, input)` is considered a singleton.  Thus, a vector of inputs must be done by:

```julia
o = HyperLogLog(4)
for yi in y
    fit!(o, yi)
end
```

[Top](#table-of-contents)
# KMeans
Approximate K-Means clustering of multivariate data.

```julia
o = KMeans(y, 3, LearningRate())
value(o)
```

[Top](#table-of-contents)
# LearningRate
`LearningRate(r = 0.6, λ = 0.0)`.

Weight at update `t` is `1 / t ^ r`.  When weights reach `λ`, hold weights constant.  Compare to `LearningRate2`.

[Top](#table-of-contents)
# LearningRate2
`LearningRate2(c = 0.5, λ = 0.0)`.

Weight at update `t` is `1 / (1 + c * (t - 1))`.  When weights reach `λ`, hold weights constant.  Compare to `LearningRate`.

[Top](#table-of-contents)
# LinReg
Linear regression with optional regularization.

```julia
LinReg(x::Matrix, y::Vector, pen::Penalty = NoPenalty())
```

Examples:

```julia
using  StatsBase
n, p = 100_000, 10
x = randn(n, p)
y = x * collect(1.:p) + randn(n)
```

Methods for `LinReg{NoPenalty}`:

```julia
o = LinReg(x, y)  # NoPenalty() by default
coef(o)
predict(o, x)
confint(o, .95)
vcov(o)
stderr(o)
coeftable(o)
using Plots; coefplot(o)
```

Get estimate for a different penalty:

```
coef(o, RidgePenalty(.1))
coef(o, LassoPenalty(.1))
coef(o, ElasticNetPenalty(.1, .5))
coef(o, SCADPenalty(.1, 3.7))
```

[Top](#table-of-contents)
# Mean
Univariate mean.

```julia
o = Mean(y, EqualWeight())
o = Mean(y)
fit!(o, y2)
mean(o)
```

[Top](#table-of-contents)
# Means
Means of multiple series, similar to `mean(x, 1)`.

```julia
o = Means(x, EqualWeight())
o = Means(x)
fit!(o, x2)
mean(o)
```

[Top](#table-of-contents)
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

[Top](#table-of-contents)
# NormalMix
Normal Mixture of `k` components via an online EM algorithm.  `start` is a keyword argument specifying the initial parameters.

```julia
o = NormalMix(2, LearningRate(); start = MixtureModel(Normal, [(0, 1), (3, 1)]))
mean(o)
var(o)
std(o)
```

[Top](#table-of-contents)
# QuantReg
Online MM Algorithm for Quantile Regression.

[Top](#table-of-contents)
# QuantileMM
Approximate quantiles via an online MM algorithm.  Typically more accurate than `QuantileSGD`.

```julia
o = QuantileMM(y, LearningRate())
o = QuantileMM(y, tau = [.25, .5, .75])
fit!(o, y2)
```

[Top](#table-of-contents)
# QuantileSGD
Approximate quantiles via stochastic gradient descent.

```julia
o = QuantileSGD(y, LearningRate())
o = QuantileSGD(y, tau = [.25, .5, .75])
fit!(o, y2)
```

[Top](#table-of-contents)
# StatLearn
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

[Top](#table-of-contents)
# StatLearnCV
`StatLearnCV(o::StatLearn, xtest, ytest)`

Automatically tune the regularization parameter λ for `o` by minimizing loss on test data `xtest`, `ytest`.

```julia
sl = StatLearn(size(x, 2), LassoPenalty(.1))
o = StatLearnCV(sl, xtest, ytest)
fit!(o, x, y)
```

[Top](#table-of-contents)
# StatLearnSparse
Enforce sparsity on a `StatLearn` object.  Currently, the only option is `HardThreshold`, which after `burnin` observations, any coefficient less than `threshold` is set to 0.

```julia
StatLearnSparse(StatLearn(size(x,2)), HardThreshold(burnin = 1000, threshold = .01))
fit!(o, x, y)
```

[Top](#table-of-contents)
# Sum
Track the running sum.  Ignores `Weight`.

```julia
o = Sum()
o = Sum(y)
```

[Top](#table-of-contents)
# Sums
Track the running sum for multiple series.  Ignores `Weight`.

```julia
o = Sums()
o = Sums(y)
```

[Top](#table-of-contents)
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

[Top](#table-of-contents)
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

[Top](#table-of-contents)
# fit!
`fit!(o::OnlineStat, input...)`

Include more data for an OnlineStat.

There are multiple `fit!` methods for each OnlineStat.

  * Adding an `Integer` after the input arguments will perform minibatch updates.

```
y = randn(100)
o = Mean()
fit!(o, y, 10)
```

  * Adding a `Float64` after the input arguments will override the weight

```julia
y = randn(100)
wts = rand(100)

o = Mean()
fit!(o, y, .1)   # Use weight of .1 for each update
fit!(o, y, wts)  # Update the Mean with y[i] using wts[i]
```

[Top](#table-of-contents)
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

[Top](#table-of-contents)
# nobs
nobs(obj::StatisticalModel)

Returns the number of independent observations on which the model was fitted. Be careful when using this information, as the definition of an independent observation may vary depending on the model, on the format used to pass the data, on the sampling plan (if specified), etc.

[Top](#table-of-contents)
# sweep!
`sweep!(A, k, inv = false)`, `sweep!(A, k, v, inv = false)`

Symmetric sweep operator of the matrix `A` on element `k`.  `A` is overwritten. `inv = true` will perform the inverse sweep.  Only the upper triangle is read and swept.

An optional vector `v` can be provided to avoid memory allocation. This requires `length(v) == size(A, 1)`.  Both `A` and `v` will be overwritten.

```julia
x = randn(100, 10)
xtx = x'x
sweep!(xtx, 1)
sweep!(xtx, 1, true)
```

[Top](#table-of-contents)
# value
The associated value of an OnlineStat.

```
o1 = Mean()
o2 = Variance()
value(o1)
value(o2)
```

[Top](#table-of-contents)
