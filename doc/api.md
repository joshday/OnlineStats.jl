<!--- Generated at 2017-04-11T11:24:40.075.  Don't edit --->

# OnlineStats API

- [Bootstrap](#Bootstrap)
- [BoundedEqualWeight](#BoundedEqualWeight)
- [CovMatrix](#CovMatrix)
- [Diff](#Diff)
- [EqualWeight](#EqualWeight)
- [ExponentialWeight](#ExponentialWeight)
- [Extrema](#Extrema)
- [FitBeta](#FitBeta)
- [FitCategorical](#FitCategorical)
- [FitCauchy](#FitCauchy)
- [FitGamma](#FitGamma)
- [FitLogNormal](#FitLogNormal)
- [FitMultinomial](#FitMultinomial)
- [FitMvNormal](#FitMvNormal)
- [FitNormal](#FitNormal)
- [HyperLogLog](#HyperLogLog)
- [KMeans](#KMeans)
- [LearningRate](#LearningRate)
- [LearningRate2](#LearningRate2)
- [MV](#MV)
- [Mean](#Mean)
- [Moments](#Moments)
- [NormalMix](#NormalMix)
- [OnlineStat](#OnlineStat)
- [OrderStats](#OrderStats)
- [QuantileMM](#QuantileMM)
- [QuantileSGD](#QuantileSGD)
- [Series](#Series)
- [Sum](#Sum)
- [Variance](#Variance)
- [Weight](#Weight)
- [confint](#confint)
- [fit!](#fit!)
- [maprows](#maprows)
- [nobs](#nobs)
- [nups](#nups)
- [replicates](#replicates)
- [stats](#stats)
- [value](#value)
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

## BoundedEqualWeight 
BoundedEqualWeight(λ::Real = 0.1) BoundedEqualWeight(lookback::Integer)

  * Use EqualWeight until threshold `λ` is hit, then hold constant.
  * Singleton weight at observation `t` is `γ = max(1 / t, λ)`

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

## EqualWeight 
```
EqualWeight()
```

  * Equally weighted observations
  * Singleton weight at observation `t` is `γ = 1 / t`

## ExponentialWeight 
```
ExponentialWeight(λ::Real = 0.1)
ExponentialWeight(lookback::Integer)
```

  * Exponentially weighted observations (constant)
  * Singleton weight at observation `t` is `γ = λ`

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

## HyperLogLog 
```
HyperLogLog(b)  # 4 ≤ b ≤ 16
```

Approximate count of distinct elements.

### Example

```
s = Series(rand(1:10, 1000), HyperLogLog(12))
```

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

## LearningRate 
```
LearningRate(r = .6, λ = 0.0)
```

  * Mainly for stochastic approximation types (`QuantileSGD`, `QuantileMM` etc.)
  * Decreases at a "slow" rate until threshold `λ` is reached
  * Singleton weight at observation `t` is `γ = max(1 / t ^ r, λ)`

## LearningRate2 
```
LearningRate2(c = .5, λ = 0.0)
```

  * Mainly for stochastic approximation types (`QuantileSGD`, `QuantileMM` etc.)
  * Decreases at a "slow" rate until threshold `λ` is reached
  * Singleton weight at observation `t` is `γ = max(inv(1 + c * (t - 1), λ)`

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

## confint 
```
confint(b, coverageprob = .95, method = :quantile)
```

Return a confidence interval for a Bootstrap `b` by method

  * `:quantile`: use quantiles of `states = value(b)`
  * `:normal`: quantiles from gaussian approximation

## fit! 
No documentation found.

`StatsBase.fit!` is a `Function`.

```
# 1866 methods for generic function "fit!":
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:71
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:51
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:71
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:51
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:71
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:51
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:71
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:51
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:71
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:51
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:71
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:51
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:71
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:51
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:71
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:51
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:71
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:51
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:71
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:51
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:70
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:51
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:70
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:57
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:70
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:55
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:24
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:115
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:138
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:164
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:182
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:195
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:219
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:70
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:11
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:60
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:82
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:108
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:146
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:181
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:20
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:39
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:69
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:91
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:155
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:190
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:19
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:38
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:68
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:90
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:116
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:154
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:189
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:14
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:33
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:63
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:85
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:111
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:149
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:184
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:14
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:33
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:63
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:85
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:111
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:149
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:184
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:14
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:33
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:63
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:85
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:111
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:149
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:184
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:14
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:33
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:63
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:85
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:111
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:149
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:184
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:8
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:27
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:57
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:79
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:105
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:143
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:178
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:12
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:31
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:61
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:83
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:109
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:147
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:182
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:10
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:29
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:59
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:81
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:107
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:145
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:180
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:8
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:27
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:57
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:79
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:105
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:143
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:178
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:8
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:23
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:49
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:71
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:97
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:135
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:170
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:14
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:29
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:55
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:77
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:103
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:141
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:176
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:17
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:32
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:58
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:80
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:106
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:144
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:179
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:15
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:30
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:56
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:78
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:104
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:142
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:177
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:15
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:38
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:72
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:94
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:120
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:158
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:193
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:15
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:38
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:72
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:98
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:129
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:167
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:202
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:54
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:11
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:8
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:27
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:118
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:141
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:167
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:185
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:198
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:222
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:50
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:18
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:18
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:28
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:73
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:96
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:122
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:140
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:153
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:177
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:50
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:18
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:18
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:28
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:74
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:98
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:125
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:144
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:158
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:183
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:50
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:18
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:18
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:28
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:74
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:98
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:125
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:144
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:158
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:183
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:50
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:18
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:18
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:28
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:74
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:98
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:125
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:144
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:158
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:183
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:50
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:18
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:18
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:28
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:74
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:98
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:125
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:144
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:158
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:183
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:50
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:18
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:18
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:28
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:74
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:98
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:125
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:144
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:158
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:183
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:50
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:18
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:18
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:28
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:74
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:98
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:125
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:144
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:158
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:183
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:50
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:18
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:18
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:28
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:74
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:98
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:125
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:144
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:158
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:183
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:50
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:18
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:18
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:28
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:74
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:98
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:125
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:144
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:158
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:183
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:50
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:18
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:18
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:28
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:74
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:98
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:125
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:144
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:158
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:183
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:50
fit!(o::OnlineStats.Mean, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:13
fit!(o::OnlineStats.Variance, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:34
fit!(o::OnlineStats.Extrema, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:66
fit!(o::OnlineStats.OrderStats, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:89
fit!(o::OnlineStats.Moments, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:117
fit!(o::OnlineStats.QuantileSGD, y::Float64, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:157
fit!(o::OnlineStats.QuantileMM, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:194
fit!(o::OnlineStats.CovMatrix, x::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/covmatrix.jl:18
fit!(o::OnlineStats.KMeans, x::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/kmeans.jl:18
fit!(o::OnlineStats.FitBeta, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:28
fit!(o::OnlineStats.FitCauchy, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:74
fit!(o::OnlineStats.FitGamma, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:98
fit!(o::OnlineStats.FitLogNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:125
fit!(o::OnlineStats.FitNormal, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:144
fit!(o::OnlineStats.FitMultinomial, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:158
fit!(o::OnlineStats.FitMvNormal, y::AbstractArray{T,1}, γ::Float64) where T<:Real in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:183
fit!(o::OnlineStats.NormalMix, y, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/normalmix.jl:74
fit!(o::OnlineStats.HyperLogLog, v, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/hyperloglog.jl:50
fit!(obj::StatsBase.StatisticalModel, data...) in StatsBase at /Users/joshday/.julia/v0.6/StatsBase/src/statmodels.jl:47
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:58
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:63
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:68
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:87
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:97
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:102
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:107
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:58
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:63
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:68
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:87
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:97
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:102
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:107
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:58
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:63
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:68
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:87
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:97
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:102
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:107
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:58
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:63
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:68
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:87
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:97
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:102
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:107
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:58
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:63
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:68
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:87
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:97
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:102
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:107
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:58
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:63
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:68
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:87
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:97
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:102
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:107
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:58
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:63
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:68
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:87
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:97
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:102
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:107
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:58
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:63
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:68
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:87
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:97
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:102
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:107
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:46
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:226
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:230
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:235
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:252
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:253
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:229
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:234
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:251
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:252
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:224
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:229
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:246
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:247
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:224
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:229
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:246
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:247
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:224
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:229
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:246
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:247
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:224
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:229
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:246
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:247
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:218
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:223
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:240
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:222
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:227
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:244
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:245
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:220
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:225
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:242
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:243
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:218
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:223
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:240
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:210
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:215
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:232
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:233
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:216
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:221
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:238
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:239
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:219
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:224
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:242
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:217
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:222
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:239
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:240
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:233
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:238
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:255
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:256
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:242
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:247
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:264
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:265
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:237
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:242
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:259
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:237
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:242
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:259
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:70
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:75
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:82
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:22
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:49
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:68
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:73
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:80
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:84
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:70
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:75
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:80
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:86
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:92
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:99
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:109
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:114
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:119
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:125
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:131
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:137
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:30
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:50
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:68
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:73
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:80
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:84
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:69
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:79
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:85
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:91
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:98
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:108
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:118
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:124
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:130
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:136
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:30
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:50
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:68
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:73
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:80
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:84
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:69
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:79
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:85
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:91
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:98
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:108
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:118
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:124
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:130
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:136
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:30
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:50
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:68
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:73
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:80
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:84
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:69
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:79
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:85
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:91
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:98
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:108
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:118
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:124
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:130
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:136
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:30
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:50
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:68
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:73
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:80
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:84
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:69
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:79
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:85
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:91
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:98
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:108
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:118
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:124
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:130
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:136
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:30
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:50
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:68
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:73
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:80
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:84
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:69
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:79
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:85
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:91
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:98
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:108
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:118
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:124
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:130
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:136
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:30
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:50
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:68
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:73
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:80
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:84
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:69
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:79
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:85
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:91
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:98
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:108
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:118
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:124
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:130
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:136
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:30
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:50
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:68
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:73
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:80
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:84
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:69
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:79
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:85
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:91
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:98
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:108
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:118
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:124
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:130
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:136
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:69
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:79
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:85
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:91
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:98
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:108
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:118
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:124
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:130
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:136
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:30
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:50
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:69
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:79
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:85
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:91
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:98
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:108
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:118
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:124
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:130
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:136
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:30
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:50
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:68
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:73
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:80
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:84
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:69
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:74
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:79
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:85
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:91
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:98
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:108
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:113
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:118
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:124
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:130
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:136
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:30
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:50
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:68
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:73
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:80
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:84
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:72
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::Real, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:77
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:82
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:88
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:94
fit!(s::OnlineStats.Series{0,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:101
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:111
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:116
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:121
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:127
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, γ::AbstractArray{Float64,1}) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:133
fit!(s::OnlineStats.Series{1,OS,W} where W<:OnlineStats.Weight where OS<:Union{OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM, Tuple}, y::AbstractArray{T,2} where T, b::Integer) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:139
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:236
fit!(o::OnlineStats.Diff{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:241
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:AbstractFloat in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:260
fit!(o::OnlineStats.Sum{T}, x::Real, γ::Float64) where T<:Integer in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/scalarinput/summary.jl:261
fit!(o::OnlineStats.MV, y::AbstractArray{T,1} where T, γ::Float64) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/vectorinput/mv.jl:30
fit!(o::OnlineStats.FitCategorical{T}, y::T, γ::Float64) where T in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/distributions.jl:50
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::Real) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:74
fit!(b::OnlineStats.Bootstrap{0,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{0,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{0,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:79
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,1} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:86
fit!(b::OnlineStats.Bootstrap{1,D,O,S,F} where F<:Function where S<:(OnlineStats.Series{1,O,W} where W<:OnlineStats.Weight) where O<:(OnlineStats.OnlineStat{1,OUTDIM} where OUTDIM) where D, y::AbstractArray{T,2} where T) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:90
```

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

## nobs 
```
nobs(obj::StatisticalModel)
```

Returns the number of independent observations on which the model was fitted. Be careful when using this information, as the definition of an independent observation may vary depending on the model, on the format used to pass the data, on the sampling plan (if specified), etc.

## nups 
No documentation found.

`OnlineStats.nups` is a `Function`.

```
# 2 methods for generic function "nups":
nups(w::OnlineStats.Weight) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/weight.jl:22
nups(o::OnlineStats.AbstractSeries) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/series.jl:11
```

## replicates 
No documentation found.

`OnlineStats.replicates` is a `Function`.

```
# 1 method for generic function "replicates":
replicates(b::OnlineStats.Bootstrap) in OnlineStats at /Users/joshday/.julia/v0.6/OnlineStats/src/streamstats/bootstrap.jl:37
```

## stats 
Return the `stats` field of a Series.

## value 
Map `value` to the `stats` field of a Series.

