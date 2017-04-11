<!--- Generated at 2017-04-11T12:03:33.807.  Don't edit --->

# OnlineStats API

# Contents
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
- [MV](#mv)
- [Mean](#mean)
- [Moments](#moments)
- [NormalMix](#normalmix)
- [OnlineStat](#onlinestat)
- [OrderStats](#orderstats)
- [QuantileMM](#quantilemm)
- [QuantileSGD](#quantilesgd)
- [Series](#series)
- [Sum](#sum)
- [Variance](#variance)
- [Weight](#weight)
- [confint](#confint)
- [fit!](#fit!)
- [maprows](#maprows)
- [nobs](#nobs)
- [nups](#nups)
- [replicates](#replicates)
- [stats](#stats)
- [value](#value)
---

## Bootstrap
```
Bootstrap(s::Series, nreps, d, fun = value)
```

Online Statistical Bootstrapping.

Create `nreps` replicates of the OnlineStat in Series `s`.  When `fit!` is called, each of the replicates will be updated `rand(d)` times.  Standard choices for `d` are `Distributions.Poisson()`, `[0, 2]`, etc.  `value(b)` returns `fun` mapped to the replicates.

### Example

```
b = Bootstrap(Series(Mean()), 100, [0, 2])
fit!(b, randn(1000))
value(b)        # `fun` mapped to replicates
mean(value(b))  # mean
```

[top](#contents)
## BoundedEqualWeight
```
BoundedEqualWeight(λ::Real = 0.1)
BoundedEqualWeight(lookback::Integer)
```

  * Use EqualWeight until threshold `λ` is hit, then hold constant.
  * Singleton weight at observation `t` is `γ = max(1 / t, λ)`

[top](#contents)
## CovMatrix
```
CovMatrix(d)
```

Covariance Matrix of `d` variables.

### Example

```
y = randn(100, 5)
Series(y, CovMatrix(5))
```

[top](#contents)
## Diff
```
Diff()
```

Track the difference and the last value.

### Example

```
s = Series(randn(1000), Diff())
value(s)
```

[top](#contents)
## EqualWeight
```
EqualWeight()
```

  * Equally weighted observations
  * Singleton weight at observation `t` is `γ = 1 / t`

[top](#contents)
## ExponentialWeight
```
ExponentialWeight(λ::Real = 0.1)
ExponentialWeight(lookback::Integer)
```

  * Exponentially weighted observations (constant)
  * Singleton weight at observation `t` is `γ = λ`

[top](#contents)
## Extrema
```
Extrema()
```

Maximum and minimum.

### Example

```
s = Series(randn(100), Extrema())
value(s)
```

[top](#contents)
## FitBeta
```
FitBeta()
```

Online parameter estimate of a Beta distribution (Method of Moments)

# Example

```
using Distributions, OnlineStats
y = rand(Beta(3, 5), 1000)
s = Series(y, FitBeta())
```

[top](#contents)
## FitCategorical
No documentation found.

`OnlineStats.FitCategorical` is of type `UnionAll`.

**Summary:**

```
struct UnionAll <: Type{T}
```

**Fields:**

```
var  :: TypeVar
body :: Any
```

[top](#contents)
## FitCauchy
```
FitCauchy()
```

Online parameter estimate of a Cauchy distribution

### Example

```
using Distributions
y = rand(Cauchy(0, 10), 10_000)
s = Series(y, FitCauchy())
```

[top](#contents)
## FitGamma
```
FitGamma()
```

Online parameter estimate of a Gamma distribution (Method of Moments)

### Example

```
using Distributions
y = rand(Gamma(5, 1), 1000)
s = Series(y, FitGamma())
```

[top](#contents)
## FitLogNormal
```
FitLogNormal()
```

Online parameter estimate of a LogNormal distribution (MLE)

### Example

```
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
```
FitMvNormal(d)
```

Online parameter estimate of a `d`-dimensional MvNormal distribution (MLE)

### Example

```
using Distributions
y = rand(MvNormal(zeros(3), eye(3)), 1000)
s = Series(y', FitMvNormal(3))
```

[top](#contents)
## FitNormal
```
FitNormal()
```

Online parameter estimate of a Normal distribution (MLE)

### FitNormal()

```
using Distributions
y = rand(Normal(-3, 4), 1000)
s = Series(y, FitNormal())
```

[top](#contents)
## HyperLogLog
```
HyperLogLog(b)  # 4 ≤ b ≤ 16
```

Approximate count of distinct elements.

### Example

```
s = Series(rand(1:10, 1000), HyperLogLog(12))
```

[top](#contents)
## KMeans
```
KMeans(p, k)
```

Approximate K-Means clustering of `k` clusters of `p` variables

### Example

```
using OnlineStats, Distributions
d = MixtureModel([Normal(0), Normal(5)])
y = rand(d, 100_000, 1)
s = Series(y, LearningRate(.6), KMeans(1, 2))
```

[top](#contents)
## LearningRate
```
LearningRate(r = .6, λ = 0.0)
```

  * Mainly for stochastic approximation types (`QuantileSGD`, `QuantileMM` etc.)
  * Decreases at a "slow" rate until threshold `λ` is reached
  * Singleton weight at observation `t` is `γ = max(1 / t ^ r, λ)`

[top](#contents)
## LearningRate2
```
LearningRate2(c = .5, λ = 0.0)
```

  * Mainly for stochastic approximation types (`QuantileSGD`, `QuantileMM` etc.)
  * Decreases at a "slow" rate until threshold `λ` is reached
  * Singleton weight at observation `t` is `γ = max(inv(1 + c * (t - 1), λ)`

[top](#contents)
## MV
```
MV(p, o)
```

Track `p` univariate OnlineStats `o`

# Example

```
y = randn(1000, 5)
o = MV(5, Mean())
s = Series(y, o)
```

[top](#contents)
## Mean
```
Mean()
```

Univariate mean.

### Example

```
s = Series(randn(100), Mean())
value(s)
```

[top](#contents)
## Moments
```
Moments()
```

First four non-central moments.

### Example

```
s = Series(randn(1000), Moments(10))
value(s)
```

[top](#contents)
## NormalMix
```
NormalMix(k)
NormalMix(k, init_data)
NormalMix(k, μ, σ2, π)
```

Univariate mixture of gaussians.  Constructor can optionally take:

  * a small batch of data to come up with smarter initial values
  * Initial vectors for means, variances, and component probabilities

### Example

```
using OnlineStats, Distributions
d = MixtureModel([Normal(0,1), Normal(4,5)], [.4, .6])
s = Series(rand(d, 100_000), NormalMix(2))
```

[top](#contents)
## OnlineStat
No documentation found.

`OnlineStats.OnlineStat` is of type `UnionAll`.

**Summary:**

```
struct UnionAll <: Type{T}
```

**Fields:**

```
var  :: TypeVar
body :: Any
```

[top](#contents)
## OrderStats
```
OrderStats(b)
```

Average order statistics with batches of size `b`.

### Example

```
s = Series(randn(1000), OrderStats(10))
value(s)
```

[top](#contents)
## QuantileMM
```
QuantileMM()
```

Approximate quantiles via an online MM algorithm.

### Example

```
s = Series(randn(1000), LearningRate(.7), QuantileMM())
value(s)
```

[top](#contents)
## QuantileSGD
```
QuantileSGD()
```

Approximate quantiles via stochastic gradient descent.

### Example

```
s = Series(randn(1000), LearningRate(.7), QuantileSGD())
value(s)
```

[top](#contents)
## Series
```
Series(onlinestats...)
Series(weight, onlinestats...)
Series(data, onlinestats...)
Series(data, weight, onlinestats...)
```

Manager for an OnlineStat or tuple of OnlineStats.

```
s = Series(Mean())
s = Series(ExponentialWeight(), Mean(), Variance())
s = Series(randn(100, 3), CovMatrix(3))
```

[top](#contents)
## Sum
```
Sum()
```

Track the overall sum.

### Example

```
s = Series(randn(1000), Sum())
value(s)
```

[top](#contents)
## Variance
```
Variance()
```

Univariate variance.

### Example

```
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
## confint
```
confint(b, coverageprob = .95, method = :quantile)
```

Return a confidence interval for a Bootstrap `b` by method

  * `:quantile`: use quantiles of `states = value(b)`
  * `:normal`: quantiles from gaussian approximation

[top](#contents)
## fit!
```
fit!(s, y)
fit!(s, y, w)
```

Update a Series `s` with more data `y` and optional weighting `w`.

[top](#contents)
## maprows
```
maprows(f::Function, b::Integer, data...)
```

Map rows of `data` in batches of size `b`.  Most usage is done through `do` blocks:

```
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
Return the number of updates

[top](#contents)
## replicates
```
replicates(b)
```

Return the vector of replicates from Bootstrap `b`

[top](#contents)
## stats
Return the `stats` field of a Series.

[top](#contents)
## value
Map `value` to the `stats` field of a Series.

[top](#contents)
