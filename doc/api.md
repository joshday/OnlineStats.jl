<!--- Generated at 2017-04-28T15:48:24.543.  Don't edit --->

# OnlineStats API

# Contents
- [ADAGRAD](#adagrad)
- [ADAM](#adam)
- [ADAMAX](#adamax)
- [Bootstrap](#bootstrap)
- [BoundedEqualWeight](#boundedequalweight)
- [CovMatrix](#covmatrix)
- [Diff](#diff)
- [EqualWeight](#equalweight)
- [ExponentialWeight](#exponentialweight)
- [Extrema](#extrema)
- [FitBeta](#fitbeta)
- [FitCategorical](#fitcategorical)
- [FitCauchy](#fitcauchy)
- [FitGamma](#fitgamma)
- [FitLogNormal](#fitlognormal)
- [FitMultinomial](#fitmultinomial)
- [FitMvNormal](#fitmvnormal)
- [FitNormal](#fitnormal)
- [HyperLogLog](#hyperloglog)
- [KMeans](#kmeans)
- [LearningRate](#learningrate)
- [LearningRate2](#learningrate2)
- [LinReg](#linreg)
- [MAXSPGD](#maxspgd)
- [MV](#mv)
- [Mean](#mean)
- [Moments](#moments)
- [NormalMix](#normalmix)
- [ObsDim](#obsdim)
- [OnlineStat](#onlinestat)
- [OrderStats](#orderstats)
- [QuantileMM](#quantilemm)
- [QuantileSGD](#quantilesgd)
- [SPGD](#spgd)
- [Series](#series)
- [StatLearn](#statlearn)
- [Sum](#sum)
- [Variance](#variance)
- [Weight](#weight)
- [classify](#classify)
- [coef](#coef)
- [coeftable](#coeftable)
- [confint](#confint)
- [fit!](#fit!)
- [loss](#loss)
- [maprows](#maprows)
- [nobs](#nobs)
- [nups](#nups)
- [objective](#objective)
- [predict](#predict)
- [replicates](#replicates)
- [statlearnpath](#statlearnpath)
- [stats](#stats)
- [value](#value)
- [vcov](#vcov)
---

## ADAGRAD
```
ADAGRAD(η)
```

Adaptive (element-wise learning rate) SPGD with step size `η`

[top](#contents)
## ADAM
```
ADAM(α1, α2, η)
```

Adaptive Moment Estimation with step size `η` and momentum parameters `α1`, `α2`

[top](#contents)
## ADAMAX
```
ADAMAX(α1, α2, η)
```

ADAMAX with step size `η` and momentum parameters `α1`, `α2`

[top](#contents)
## Bootstrap
```julia
Bootstrap(s::Series, nreps, d, f = value)
```

Online Statistical Bootstrapping.

Create `nreps` replicates of the OnlineStat in Series `s`.  When `fit!` is called, each of the replicates will be updated `rand(d)` times.  Standard choices for `d` are `Distributions.Poisson()`, `[0, 2]`, etc.  `value(b)` returns `f` mapped to the replicates.

### Example

```julia
b = Bootstrap(Series(Mean()), 100, [0, 2])
fit!(b, randn(1000))
value(b)        # `f` mapped to replicates
mean(value(b))  # mean
```

[top](#contents)
## BoundedEqualWeight
```julia
BoundedEqualWeight(λ::Real = 0.1)
BoundedEqualWeight(lookback::Integer)
```

  * Use EqualWeight until threshold `λ` is hit, then hold constant.
  * Singleton weight at observation `t` is `γ = max(1 / t, λ)`

[top](#contents)
## CovMatrix
```julia
CovMatrix(d)
```

Covariance Matrix of `d` variables.

### Example

```julia
y = randn(100, 5)
Series(y, CovMatrix(5))
```

[top](#contents)
## Diff
```julia
Diff()
```

Track the difference and the last value.

### Example

```julia
s = Series(randn(1000), Diff())
value(s)
```

[top](#contents)
## EqualWeight
```julia
EqualWeight()
```

  * Equally weighted observations
  * Singleton weight at observation `t` is `γ = 1 / t`

[top](#contents)
## ExponentialWeight
```julia
ExponentialWeight(λ::Real = 0.1)
ExponentialWeight(lookback::Integer)
```

  * Exponentially weighted observations (constant)
  * Singleton weight at observation `t` is `γ = λ`

[top](#contents)
## Extrema
```julia
Extrema()
```

Maximum and minimum.

### Example

```julia
s = Series(randn(100), Extrema())
value(s)
```

[top](#contents)
## FitBeta
```julia
FitBeta()
```

Online parameter estimate of a Beta distribution (Method of Moments)

### Example

```julia
using Distributions, OnlineStats
y = rand(Beta(3, 5), 1000)
s = Series(y, FitBeta())
```

[top](#contents)
## FitCategorical
```julia
FitCategorical(T)
```

Fit a categorical distribution where the inputs are of type `T`.

# Example

```julia
using Distributions
s = Series(rand(1:10, 1000), FitCategorical(Int))
keys(stats(s))      # inputs (categories)
probs(value(s))     # probability vector associated with keys

vals = ["small", "medium", "large"]
s = Series(rand(vals, 1000), FitCategorical(String))
```

[top](#contents)
## FitCauchy
```julia
FitCauchy()
```

Online parameter estimate of a Cauchy distribution

### Example

```julia
using Distributions
y = rand(Cauchy(0, 10), 10_000)
s = Series(y, FitCauchy())
```

[top](#contents)
## FitGamma
```julia
FitGamma()
```

Online parameter estimate of a Gamma distribution (Method of Moments)

### Example

```julia
using Distributions
y = rand(Gamma(5, 1), 1000)
s = Series(y, FitGamma())
```

[top](#contents)
## FitLogNormal
```julia
FitLogNormal()
```

Online parameter estimate of a LogNormal distribution (MLE)

### Example

```julia
using Distributions
y = rand(LogNormal(3, 4), 1000)
s = Series(y, FitLogNormal())
```

[top](#contents)
## FitMultinomial
No documentation found.

**Summary:**

```
mutable struct OnlineStats.FitMultinomial <: OnlineStats.OnlineStat{1,Distributions.Distribution}
```

**Fields:**

```
mvmean :: OnlineStats.MV{OnlineStats.Mean}
nobs   :: Int64
```

[top](#contents)
## FitMvNormal
```julia
FitMvNormal(d)
```

Online parameter estimate of a `d`-dimensional MvNormal distribution (MLE)

### Example

```julia
using Distributions
y = rand(MvNormal(zeros(3), eye(3)), 1000)
s = Series(y', FitMvNormal(3))
```

[top](#contents)
## FitNormal
```julia
FitNormal()
```

Online parameter estimate of a Normal distribution (MLE)

### FitNormal()

```julia
using Distributions
y = rand(Normal(-3, 4), 1000)
s = Series(y, FitNormal())
```

[top](#contents)
## HyperLogLog
```julia
HyperLogLog(b)  # 4 ≤ b ≤ 16
```

Approximate count of distinct elements.

### Example

```julia
s = Series(rand(1:10, 1000), HyperLogLog(12))
```

[top](#contents)
## KMeans
```julia
KMeans(p, k)
```

Approximate K-Means clustering of `k` clusters of `p` variables

### Example

```julia
using OnlineStats, Distributions
d = MixtureModel([Normal(0), Normal(5)])
y = rand(d, 100_000, 1)
s = Series(y, LearningRate(.6), KMeans(1, 2))
```

[top](#contents)
## LearningRate
```julia
LearningRate(r = .6, λ = 0.0)
```

  * Mainly for stochastic approximation types (`QuantileSGD`, `QuantileMM` etc.)
  * Decreases at a "slow" rate until threshold `λ` is reached
  * Singleton weight at observation `t` is `γ = max(1 / t ^ r, λ)`

[top](#contents)
## LearningRate2
```julia
LearningRate2(c = .5, λ = 0.0)
```

  * Mainly for stochastic approximation types (`QuantileSGD`, `QuantileMM` etc.)
  * Decreases at a "slow" rate until threshold `λ` is reached
  * Singleton weight at observation `t` is `γ = max(inv(1 + c * (t - 1), λ)`

[top](#contents)
## LinReg
```julia
LinReg(p)
LinReg(p, λ)
```

Create a linear regression object with `p` predictors and optional ridge (L2-regularization) parameter `λ`.

### Example

```julia
x = randn(1000, 5)
y = x * linspace(-1, 1, 5) + randn(1000)
o = LinReg(5)
s = Series(o)
fit!(s, x, y)
coef(o)
predict(o, x)
coeftable(o)
vcov(o)
confint(o)
```

[top](#contents)
## MAXSPGD
```
MAXSPGD(η)
```

SPGD where only the largest gradient element is used to update the parameter.

[top](#contents)
## MV
```
MV(p, o)
```

Track `p` univariate OnlineStats `o`

### Example

```julia
y = randn(1000, 5)
o = MV(5, Mean())
s = Series(y, o)
```

[top](#contents)
## Mean
```julia
Mean()
```

Univariate mean.

### Example

```julia
s = Series(randn(100), Mean())
value(s)
```

[top](#contents)
## Moments
```julia
Moments()
```

First four non-central moments.

### Example

```julia
s = Series(randn(1000), Moments(10))
value(s)
```

[top](#contents)
## NormalMix
```julia
NormalMix(k)
NormalMix(k, init_data)
NormalMix(k, μ, σ2, π)
```

Univariate mixture of gaussians.  Constructor can optionally take:

  * a small batch of data to come up with smarter initial values
  * Initial vectors for means, variances, and component probabilities

### Example

```julia
using OnlineStats, Distributions
d = MixtureModel([Normal(0,1), Normal(4,5)], [.4, .6])
s = Series(rand(d, 100_000), NormalMix(2))
```

[top](#contents)
## ObsDim
```
module ObsDim
```

Singleton types to define which dimension of some data structure (e.g. some `Array`) denotes the observations.

  * `ObsDim.First()`
  * `ObsDim.Last()`
  * `ObsDim.Contant(dim)`

Used for efficient dispatching

[top](#contents)
## OnlineStat
```
OnlineStat{I, O}
```

Abstract type which provides input `I` and output `O` dimensions or object.

  * 0 = scalar
  * 1 = vector
  * 2 = matrix
  * -1 = unknown size
  * Distribution
  * (1, 0) = x,y pair where x is a vector, y is a scalar

[top](#contents)
## OrderStats
```julia
OrderStats(b)
```

Average order statistics with batches of size `b`.

### Example

```julia
s = Series(randn(1000), OrderStats(10))
value(s)
```

[top](#contents)
## QuantileMM
```julia
QuantileMM()
```

Approximate quantiles via an online MM algorithm.

### Example

```julia
s = Series(randn(1000), LearningRate(.7), QuantileMM())
value(s)
```

[top](#contents)
## QuantileSGD
```julia
QuantileSGD()
```

Approximate quantiles via stochastic gradient descent.

### Example

```julia
s = Series(randn(1000), LearningRate(.7), QuantileSGD())
value(s)
```

[top](#contents)
## SPGD
```
SPGD(η)
```

Stochastic Proximal Gradient Descent with step size `η`

[top](#contents)
## Series
```julia
Series(onlinestats...)
Series(weight, onlinestats...)
Series(data, onlinestats...)
Series(data, weight, onlinestats...)
```

Manager for an OnlineStat or tuple of OnlineStats.

### Examples

```julia
s = Series(Mean())
s = Series(ExponentialWeight(), Mean(), Variance())
s = Series(randn(100, 3), CovMatrix(3))
```

[top](#contents)
## StatLearn
```julia
StatLearn(p, loss, penalty, λ, updater)
```

Fit a statistical learning model of `p` independent variables for a given `loss`, `penalty`, and `λ`.  Arguments are:

  * `loss`: any Loss from LossFunctions.jl
  * `penalty`: any Penalty from PenaltyFunctions.jl.
  * `λ`: a Float64 regularization parameter
  * `updater`: `SPGD()`, `ADAGRAD()`, `ADAM()`, or `ADAMAX()`

### Example

```julia
using LossFunctions, PenaltyFunctions
x = randn(100_000, 10)
y = x * linspace(-1, 1, 10) + randn(100_000)
o = StatLearn(10, L2DistLoss(), L1Penalty(), .1, SPGD())
s = Series(o)
fit!(s, x, y)
coef(o)
predict(o, x)
```

[top](#contents)
## Sum
```julia
Sum()
```

Track the overall sum.

### Example

```julia
s = Series(randn(1000), Sum())
value(s)
```

[top](#contents)
## Variance
```julia
Variance()
```

Univariate variance.

### Example

```julia
s = Series(randn(100), Variance())
value(s)
```

[top](#contents)
## Weight
No documentation found.

**Summary:**

```
abstract type OnlineStats.Weight <: Any
```

**Subtypes:**

```
OnlineStats.BoundedEqualWeight
OnlineStats.EqualWeight
OnlineStats.ExponentialWeight
OnlineStats.LearningRate
OnlineStats.LearningRate2
```

[top](#contents)
## classify
No documentation found.

`OnlineStats.classify` is a `Function`.

```
# 1 method for generic function "classify":
classify(o::OnlineStats.StatLearn, x) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/xyinput/statlearn.jl:53
```

[top](#contents)
## coef
No documentation found.

`StatsBase.coef` is a `Function`.

```
# 3 methods for generic function "coef":
coef(o::OnlineStats.LinReg) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/xyinput/linreg.jl:73
coef(obj::StatsBase.StatisticalModel) in StatsBase at /Users/joshday/.julia/v0.6/StatsBase/src/statmodels.jl:5
coef(o::OnlineStats.StatLearn) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/xyinput/statlearn.jl:50
```

[top](#contents)
## coeftable
No documentation found.

`StatsBase.coeftable` is a `Function`.

```
# 2 methods for generic function "coeftable":
coeftable(o::OnlineStats.LinReg) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/xyinput/linreg.jl:77
coeftable(obj::StatsBase.StatisticalModel) in StatsBase at /Users/joshday/.julia/v0.6/StatsBase/src/statmodels.jl:6
```

[top](#contents)
## confint
```julia
confint(b, coverageprob = .95, method = :quantile)
```

Return a confidence interval for a Bootstrap `b` by method

  * `:quantile`: use quantiles of `states = value(b)`
  * `:normal`: quantiles from gaussian approximation

[top](#contents)
## fit!
```julia
fit!(s, y)
fit!(s, y, w)
```

Update a Series `s` with more data `y` and optional weighting `w`.

### Examples

```julia
y = randn(100)
w = rand(100)

s = Series(Mean())
fit!(s, y[1])        # one observation: use Series weight
fit!(s, y[1], w[1])  # one observation: override weight
fit!(s, y)           # multiple observations: use Series weight
fit!(s, y, w[1])     # multiple observations: override each weight with w[1]
fit!(s, y, w)        # multiple observations: y[i] uses weight w[i]
```

[top](#contents)
## loss
No documentation found.

`OnlineStats.loss` is a `Function`.

```
# 1 method for generic function "loss":
loss(o::OnlineStats.StatLearn, x, y) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/xyinput/statlearn.jl:54
```

[top](#contents)
## maprows
```julia
maprows(f::Function, b::Integer, data...)
```

Map rows of `data` in batches of size `b`.  Most usage is done through `do` blocks.

### Example

```julia
s = Series(Mean())
maprows(10, randn(100)) do yi
    fit!(s, yi)
    info("nobs: $(nobs(s))")
end
```

[top](#contents)
## nobs
```
nobs(obj::StatisticalModel)
```

Returns the number of independent observations on which the model was fitted. Be careful when using this information, as the definition of an independent observation may vary depending on the model, on the format used to pass the data, on the sampling plan (if specified), etc.

[top](#contents)
## nups
```julia
nups(Series(Mean()))
```

Return the number of updates a series has done.  Differs from `nobs` only when batch updates have been used.

[top](#contents)
## objective
No documentation found.

`OnlineStats.objective` is a `Function`.

```
# 1 method for generic function "objective":
objective(o::OnlineStats.StatLearn, x, y) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/xyinput/statlearn.jl:56
```

[top](#contents)
## predict
```
predict(obj::RegressionModel, [newX])
```

Form the predicted response of model `obj`. An object with new covariate values `newX` can be supplied, which should have the same type and structure as that used to fit `obj`; e.g. for a GLM it would generally be a `DataFrame` with the same variable names as the original predictors.

[top](#contents)
## replicates
```julia
replicates(b)
```

Return the vector of replicates from Bootstrap `b`

[top](#contents)
## statlearnpath
```julia
statlearnpath(p, loss, pen, λvector, updater)
```

Create a vector of `StatLearn` objects, each using one of the regularization parameters in `λvector`.

### Example

```julia
s = Series(statlearnpath(5, L1DistLoss(), L1Penalty(), collect(0:.1:1), SPGD())...)
fit!(s, randn(10000, 5), randn(10000))
```

[top](#contents)
## stats
Return the `stats` field of a Series.

[top](#contents)
## value
Map `value` to the `stats` field of a Series.

[top](#contents)
## vcov
No documentation found.

`StatsBase.vcov` is a `Function`.

```
# 2 methods for generic function "vcov":
vcov(o::OnlineStats.LinReg) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/xyinput/linreg.jl:94
vcov(obj::StatsBase.StatisticalModel) in StatsBase at /Users/joshday/.julia/v0.6/StatsBase/src/statmodels.jl:45
```

[top](#contents)
