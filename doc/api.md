<!--- This file was generated at 2016-04-06T17:08:08.866.  Do not edit by hand --->
# API for OnlineStats

# Table of Contents

- [<pre>BernoulliBootstrap                                      Bootstrap{ScalarInput}</pre>](#bernoullibootstrap)
- [<pre>BoundedEqualWeight                                      Weight</pre>](#boundedequalweight)
- [<pre>CompareTracePlot                                        Any</pre>](#comparetraceplot)
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
- [<pre>TracePlot                                               OnlineStat{I<:Input}</pre>](#traceplot)
- [<pre>Variance                                                OnlineStat{ScalarInput}</pre>](#variance)
- [<pre>Variances                                               OnlineStat{VectorInput}</pre>](#variances)
- [<pre>coefplot                                                #coefplot</pre>](#coefplot)
- [<pre>fit!                                                    StatsBase.#fit!</pre>](#fit!)
- [<pre>fitdistribution                                         #fitdistribution</pre>](#fitdistribution)
- [<pre>nobs                                                    StatsBase.#nobs</pre>](#nobs)
- [<pre>sweep!                                                  #sweep!</pre>](#sweep!)
- [<pre>value                                                   #value</pre>](#value)

# AdaDelta
No documentation found.

**Summary:**

```
type OnlineStats.AdaDelta <: OnlineStats.Algorithm
```

**Fields:**

```
g0 :: Float64
g  :: Array{Float64,1}
Δ0 :: Float64
Δ  :: Array{Float64,1}
ρ  :: Float64
```

[Top](#table-of-contents)
# AdaGrad
No documentation found.

**Summary:**

```
type OnlineStats.AdaGrad <: OnlineStats.Algorithm
```

**Fields:**

```
g0 :: Float64
g  :: Array{Float64,1}
```

[Top](#table-of-contents)
# AdaGrad2
No documentation found.

**Summary:**

```
type OnlineStats.AdaGrad2 <: OnlineStats.Algorithm
```

**Fields:**

```
g0 :: Float64
g  :: Array{Float64,1}
```

[Top](#table-of-contents)
# Algorithm
No documentation found.

**Summary:**

```
abstract OnlineStats.Algorithm <: Any
```

**Subtypes:**

```
OnlineStats.AdaDelta
OnlineStats.AdaGrad
OnlineStats.AdaGrad2
OnlineStats.FOBOS
OnlineStats.MMGrad
OnlineStats.RDA
OnlineStats.SGD
OnlineStats.SGD2
```

[Top](#table-of-contents)
# BernoulliBootstrap
`BernoulliBootstrap(o::OnlineStat, f::Function, r::Int = 1000)`

Create a double-or-nothing bootstrap using `r` replicates of `o` for estimate `f(o)`

Example:

```julia
BernoulliBootstrap(Mean(), mean, 1000)
```

[Top](#table-of-contents)
# BiasMatrix
No documentation found.

**Summary:**

```
immutable OnlineStats.BiasMatrix{A<:AbstractArray{Float64,2}} <: AbstractArray{Float64,2}
```

**Fields:**

```
mat :: A<:AbstractArray{Float64,2}
```

[Top](#table-of-contents)
# BiasVector
No documentation found.

**Summary:**

```
immutable OnlineStats.BiasVector{A<:AbstractArray{Float64,1}} <: AbstractArray{Float64,1}
```

**Fields:**

```
vec :: A<:AbstractArray{Float64,1}
```

[Top](#table-of-contents)
# BoundedEqualWeight
`BoundedEqualWeight(λ::Float64)`, `BoundedEqualWeight(lookback::Int)`

Use equal weights until reaching `λ = 2 / (1 + lookback)`, then hold constant.

[Top](#table-of-contents)
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
# ElasticNetPenalty
No documentation found.

**Summary:**

```
type OnlineStats.ElasticNetPenalty <: OnlineStats.Penalty
```

**Fields:**

```
λ :: Float64
α :: Float64
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
# FitBeta
No documentation found.

**Summary:**

```
type OnlineStats.FitBeta{W<:OnlineStats.Weight} <: OnlineStats.DistributionStat{OnlineStats.ScalarInput}
```

**Fields:**

```
value :: Distributions.Beta
var   :: OnlineStats.Variance{W<:OnlineStats.Weight}
```

[Top](#table-of-contents)
# FitCategorical
Find the proportions for each unique input.  Categories are sorted by proportions. Ignores `Weight`.

```julia
o = FitCategorical(y)
```

[Top](#table-of-contents)
# FitCauchy
No documentation found.

**Summary:**

```
type OnlineStats.FitCauchy{W<:OnlineStats.Weight} <: OnlineStats.DistributionStat{OnlineStats.ScalarInput}
```

**Fields:**

```
value :: Distributions.Cauchy
q     :: OnlineStats.QuantileMM{W<:OnlineStats.Weight}
```

[Top](#table-of-contents)
# FitGamma
No documentation found.

**Summary:**

```
type OnlineStats.FitGamma{W<:OnlineStats.Weight} <: OnlineStats.DistributionStat{OnlineStats.ScalarInput}
```

**Fields:**

```
value :: Distributions.Gamma
var   :: OnlineStats.Variance{W<:OnlineStats.Weight}
```

[Top](#table-of-contents)
# FitLogNormal
No documentation found.

**Summary:**

```
type OnlineStats.FitLogNormal{W<:OnlineStats.Weight} <: OnlineStats.DistributionStat{OnlineStats.ScalarInput}
```

**Fields:**

```
value :: Distributions.LogNormal
var   :: OnlineStats.Variance{W<:OnlineStats.Weight}
```

[Top](#table-of-contents)
# FitMultinomial
No documentation found.

**Summary:**

```
type OnlineStats.FitMultinomial{W<:OnlineStats.Weight} <: OnlineStats.DistributionStat{OnlineStats.VectorInput}
```

**Fields:**

```
value :: Distributions.Multinomial
means :: OnlineStats.Means{W<:OnlineStats.Weight}
```

[Top](#table-of-contents)
# FitMvNormal
No documentation found.

**Summary:**

```
type OnlineStats.FitMvNormal{W<:OnlineStats.Weight} <: OnlineStats.DistributionStat{OnlineStats.VectorInput}
```

**Fields:**

```
value :: Distributions.MvNormal{Cov<:PDMats.AbstractPDMat{T<:Real},Mean<:Union{Array{Float64,1},Distributions.ZeroVector{Float64}}}
cov   :: OnlineStats.CovMatrix{W<:OnlineStats.Weight}
```

[Top](#table-of-contents)
# FitNormal
No documentation found.

**Summary:**

```
type OnlineStats.FitNormal{W<:OnlineStats.Weight} <: OnlineStats.DistributionStat{OnlineStats.ScalarInput}
```

**Fields:**

```
value :: Distributions.Normal
var   :: OnlineStats.Variance{W<:OnlineStats.Weight}
```

[Top](#table-of-contents)
# FrozenBootstrap
No documentation found.

**Summary:**

```
immutable OnlineStats.FrozenBootstrap <: OnlineStats.Bootstrap{OnlineStats.ScalarInput}
```

**Fields:**

```
cached_state :: Array{Float64,1}
n            :: Int64
```

[Top](#table-of-contents)
# HardThreshold
No documentation found.

**Summary:**

```
immutable OnlineStats.HardThreshold <: OnlineStats.AbstractSparsity
```

**Fields:**

```
burnin :: Int64
ϵ      :: Float64
```

[Top](#table-of-contents)
# HuberRegression
No documentation found.

**Summary:**

```
immutable OnlineStats.HuberRegression <: OnlineStats.ModelDefinition
```

**Fields:**

```
δ :: Float64
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
# L1Regression
No documentation found.

**Summary:**

```
immutable OnlineStats.L1Regression <: OnlineStats.ModelDefinition
```

[Top](#table-of-contents)
# L2Regression
No documentation found.

**Summary:**

```
immutable OnlineStats.L2Regression <: OnlineStats.GLMDef
```

[Top](#table-of-contents)
# LassoPenalty
No documentation found.

**Summary:**

```
type OnlineStats.LassoPenalty <: OnlineStats.Penalty
```

**Fields:**

```
λ :: Float64
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
coef(o, RidgePenalty(.1))  # Ridge
coef(o, LassoPenalty(.1))  # LASSO
coef(o, ElasticNetPenalty(.1, .5))
coef(o, SCADPenalty(.1, 3.7))
```

[Top](#table-of-contents)
# LogisticRegression
No documentation found.

**Summary:**

```
immutable OnlineStats.LogisticRegression <: OnlineStats.GLMDef
```

[Top](#table-of-contents)
# MMGrad
No documentation found.

**Summary:**

```
type OnlineStats.MMGrad <: OnlineStats.Algorithm
```

**Fields:**

```
α  :: Function
h0 :: Float64
h  :: Array{Float64,1}
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
# ModelDefinition
No documentation found.

**Summary:**

```
abstract OnlineStats.ModelDefinition <: Any
```

**Subtypes:**

```
OnlineStats.GLMDef
OnlineStats.HuberRegression
OnlineStats.L1Regression
OnlineStats.QuantileRegression
OnlineStats.SVMLike
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
# NoPenalty
No documentation found.

**Summary:**

```
immutable OnlineStats.NoPenalty <: OnlineStats.Penalty
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
# OnlineStat
No documentation found.

**Summary:**

```
abstract OnlineStats.OnlineStat{I<:OnlineStats.Input} <: Any
```

**Subtypes:**

```
OnlineStats.Bootstrap{I<:OnlineStats.Input}
OnlineStats.CovMatrix{W<:OnlineStats.Weight}
OnlineStats.Diffs{T<:Real}
OnlineStats.Diff{T<:Real}
OnlineStats.DistributionStat{I<:OnlineStats.Input}
OnlineStats.Extrema
OnlineStats.HyperLogLog
OnlineStats.KMeans{W<:OnlineStats.Weight}
OnlineStats.LinReg{W<:OnlineStats.Weight}
OnlineStats.Means{W<:OnlineStats.Weight}
OnlineStats.Mean{W<:OnlineStats.Weight}
OnlineStats.Moments{W<:OnlineStats.Weight}
OnlineStats.QuantReg{W<:OnlineStats.Weight}
OnlineStats.QuantileMM{W<:OnlineStats.Weight}
OnlineStats.QuantileSGD{W<:OnlineStats.StochasticWeight}
OnlineStats.StatLearnCV{T<:Real,S<:Real,W<:OnlineStats.Weight}
OnlineStats.StatLearnSparse{S<:OnlineStats.AbstractSparsity}
OnlineStats.StatLearn{A<:OnlineStats.Algorithm,M<:OnlineStats.ModelDefinition,P<:OnlineStats.Penalty,W<:OnlineStats.Weight}
OnlineStats.Sums{T<:Real}
OnlineStats.Sum{T<:Real}
OnlineStats.TracePlot
OnlineStats.Variances{W<:OnlineStats.Weight}
OnlineStats.Variance{W<:OnlineStats.Weight}
```

[Top](#table-of-contents)
# Penalty
No documentation found.

**Summary:**

```
abstract OnlineStats.Penalty <: Any
```

**Subtypes:**

```
OnlineStats.ElasticNetPenalty
OnlineStats.LassoPenalty
OnlineStats.NoPenalty
OnlineStats.RidgePenalty
OnlineStats.SCADPenalty
```

[Top](#table-of-contents)
# PoissonBootstrap
No documentation found.

`OnlineStats.PoissonBootstrap` is a `Function`.

```
# 4 methods for generic function "PoissonBootstrap":
PoissonBootstrap{T<:OnlineStats.ScalarInput}(o::OnlineStats.OnlineStat{T}, f::Function) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:63
PoissonBootstrap{T<:OnlineStats.ScalarInput}(o::OnlineStats.OnlineStat{T}, f::Function, r::Int64) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:63
PoissonBootstrap{T<:OnlineStats.VectorInput}(o::OnlineStats.OnlineStat{T}, f::Function) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:76
PoissonBootstrap{T<:OnlineStats.VectorInput}(o::OnlineStats.OnlineStat{T}, f::Function, r::Int64) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:76
```

[Top](#table-of-contents)
# PoissonRegression
No documentation found.

**Summary:**

```
immutable OnlineStats.PoissonRegression <: OnlineStats.GLMDef
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
# QuantileRegression
No documentation found.

**Summary:**

```
immutable OnlineStats.QuantileRegression <: OnlineStats.ModelDefinition
```

**Fields:**

```
τ :: Float64
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
# RDA
No documentation found.

**Summary:**

```
type OnlineStats.RDA <: OnlineStats.Algorithm
```

**Fields:**

```
g0    :: Float64
g     :: Array{Float64,1}
gbar0 :: Float64
gbar  :: Array{Float64,1}
```

[Top](#table-of-contents)
# RidgePenalty
No documentation found.

**Summary:**

```
type OnlineStats.RidgePenalty <: OnlineStats.Penalty
```

**Fields:**

```
λ :: Float64
```

[Top](#table-of-contents)
# SCADPenalty
No documentation found.

**Summary:**

```
type OnlineStats.SCADPenalty <: OnlineStats.Penalty
```

**Fields:**

```
λ :: Float64
a :: Float64
```

[Top](#table-of-contents)
# SGD
No documentation found.

**Summary:**

```
immutable OnlineStats.SGD <: OnlineStats.Algorithm
```

[Top](#table-of-contents)
# SVMLike
No documentation found.

**Summary:**

```
immutable OnlineStats.SVMLike <: OnlineStats.ModelDefinition
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
# Weight
No documentation found.

**Summary:**

```
abstract OnlineStats.Weight <: Any
```

**Subtypes:**

```
OnlineStats.BatchWeight
OnlineStats.BoundedEqualWeight
OnlineStats.ExponentialWeight
```

[Top](#table-of-contents)
# cached_state
No documentation found.

`OnlineStats.cached_state` is a `Function`.

```
# 3 methods for generic function "cached_state":
cached_state(b::OnlineStats.FrozenBootstrap) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:103
cached_state(b::OnlineStats.Bootstrap{OnlineStats.ScalarInput}) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:116
cached_state(b::OnlineStats.Bootstrap{OnlineStats.VectorInput}) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:125
```

[Top](#table-of-contents)
# center
No documentation found.

`OnlineStats.center` is a `Function`.

```
# 4 methods for generic function "center":
center(o::OnlineStats.Mean{W<:OnlineStats.Weight}, x::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/summary.jl:22
center{T<:Real}(o::OnlineStats.Means{W<:OnlineStats.Weight}, x::AbstractArray{T,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/summary.jl:46
center(o::OnlineStats.Variance{W<:OnlineStats.Weight}, x::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/summary.jl:78
center{T<:Real}(o::OnlineStats.Variances{W<:OnlineStats.Weight}, x::AbstractArray{T,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/summary.jl:121
```

[Top](#table-of-contents)
# coef
No documentation found.

`StatsBase.coef` is a `Function`.

```
# 7 methods for generic function "coef":
coef(obj::StatsBase.StatisticalModel) at /Users/joshday/.julia/v0.5/StatsBase/src/statmodels.jl:5
coef(o::OnlineStats.StatLearn{A<:OnlineStats.Algorithm,M<:OnlineStats.ModelDefinition,P<:OnlineStats.Penalty,W<:OnlineStats.Weight}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:191
coef(o::OnlineStats.StatLearnSparse{S<:OnlineStats.AbstractSparsity}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearnextensions.jl:38
coef(o::OnlineStats.StatLearnCV{T<:Real,S<:Real,W<:OnlineStats.Weight}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearnextensions.jl:140
coef(o::OnlineStats.LinReg{W<:OnlineStats.Weight}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/linreg.jl:131
coef(o::OnlineStats.LinReg{W<:OnlineStats.Weight}, penalty::OnlineStats.Penalty; maxiters, tolerance, step, verbose) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/linreg.jl:82
coef(o::OnlineStats.QuantReg{W<:OnlineStats.Weight}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/quantreg.jl:19
```

[Top](#table-of-contents)
# coefplot
For any OnlineStat that has a `coef` method, display a graphical representation of the coefficient vector.

```julia
using Plots
o = LinReg(x, y)
coefplot(o)
```

[Top](#table-of-contents)
# cost
No documentation found.

`OnlineStats.cost` is a `Function`.

```
# 2 methods for generic function "cost":
cost(o::OnlineStats.StatLearn{A<:OnlineStats.Algorithm,M<:OnlineStats.ModelDefinition,P<:OnlineStats.Penalty,W<:OnlineStats.Weight}, x::AbstractArray{T<:Any,1}, y::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:221
cost(o::OnlineStats.StatLearn{A<:OnlineStats.Algorithm,M<:OnlineStats.ModelDefinition,P<:OnlineStats.Penalty,W<:OnlineStats.Weight}, x::AbstractArray{T<:Any,2}, y::AbstractArray{T<:Any,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:223
```

[Top](#table-of-contents)
# fit
No documentation found.

`StatsBase.fit` is a `Function`.

```
# 17 methods for generic function "fit":
fit(::Type{StatsBase.Histogram{T<:Real,N<:Any,E<:Any}}, v::AbstractArray{T<:Any,1}; closed, nbins) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:183
fit(::Type{StatsBase.Histogram{T<:Real,N<:Any,E<:Any}}, v::AbstractArray{T<:Any,1}, edg::AbstractArray{T<:Any,1}; closed) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:181
fit(::Type{StatsBase.Histogram{T<:Real,N<:Any,E<:Any}}, v::AbstractArray{T<:Any,1}, wv::StatsBase.WeightVec{W<:Any,Vec<:AbstractArray{T<:Real,1}}; closed, nbins) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:188
fit{W}(::Type{StatsBase.Histogram{T<:Real,N<:Any,E<:Any}}, v::AbstractArray{T<:Any,1}, wv::StatsBase.WeightVec{W,Vec<:AbstractArray{T<:Real,1}}, edg::AbstractArray{T<:Any,1}; closed) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:186
fit{N}(::Type{StatsBase.Histogram{T<:Real,N<:Any,E<:Any}}, vs::NTuple{N,AbstractArray{T<:Any,1}}, edges::NTuple{N,AbstractArray{T<:Any,1}}; closed) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:220
fit{N}(::Type{StatsBase.Histogram{T<:Real,N<:Any,E<:Any}}, vs::NTuple{N,AbstractArray{T<:Any,1}}; closed, nbins) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:222
fit{N}(::Type{StatsBase.Histogram{T<:Real,N<:Any,E<:Any}}, vs::NTuple{N,AbstractArray{T<:Any,1}}, wv::StatsBase.WeightVec{W<:Any,Vec<:AbstractArray{T<:Real,1}}; closed, nbins) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:227
fit{N,W}(::Type{StatsBase.Histogram{T<:Real,N<:Any,E<:Any}}, vs::NTuple{N,AbstractArray{T<:Any,1}}, wv::StatsBase.WeightVec{W,Vec<:AbstractArray{T<:Real,1}}, edges::NTuple{N,AbstractArray{T<:Any,1}}; closed) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:225
fit(obj::StatsBase.StatisticalModel, data...) at /Users/joshday/.julia/v0.5/StatsBase/src/statmodels.jl:46
fit(::Type{Distributions.Binomial}, data::Tuple{Int64,AbstractArray{T<:Any,N<:Any}}) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/binomial.jl:169
fit(::Type{Distributions.Binomial}, data::Tuple{Int64,AbstractArray{T<:Any,N<:Any}}, w::AbstractArray{Float64,N<:Any}) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/binomial.jl:170
fit(::Type{Distributions.Categorical}, data::Tuple{Int64,AbstractArray{T<:Any,N<:Any}}) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/categorical.jl:248
fit(::Type{Distributions.Categorical}, data::Tuple{Int64,AbstractArray{T<:Any,N<:Any}}, w::AbstractArray{Float64,N<:Any}) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/categorical.jl:249
fit{T<:Real}(::Type{Distributions.Beta}, x::AbstractArray{T,N<:Any}) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/beta.jl:88
fit{T<:Real}(::Type{Distributions.Cauchy}, x::AbstractArray{T,N<:Any}) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/cauchy.jl:69
fit{D<:Distributions.Distribution{F<:Distributions.VariateForm,S<:Distributions.ValueSupport}}(dt::Type{D}, x) at /Users/joshday/.julia/v0.5/Distributions/src/genericfit.jl:14
fit{D<:Distributions.Distribution{F<:Distributions.VariateForm,S<:Distributions.ValueSupport}}(dt::Type{D}, args...) at /Users/joshday/.julia/v0.5/Distributions/src/genericfit.jl:15
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
# kurtosis
No documentation found.

`StatsBase.kurtosis` is a `Function`.

```
# 52 methods for generic function "kurtosis":
kurtosis(v::AbstractArray{T<:Real,N<:Any}) at /Users/joshday/.julia/v0.5/StatsBase/src/moments.jl:270
kurtosis(v::AbstractArray{T<:Real,N<:Any}, m::Real) at /Users/joshday/.julia/v0.5/StatsBase/src/moments.jl:234
kurtosis(v::AbstractArray{T<:Real,N<:Any}, wv::StatsBase.WeightVec{W<:Any,Vec<:AbstractArray{T<:Real,1}}) at /Users/joshday/.julia/v0.5/StatsBase/src/moments.jl:271
kurtosis(v::AbstractArray{T<:Real,N<:Any}, wv::StatsBase.WeightVec{W<:Any,Vec<:AbstractArray{T<:Real,1}}, m::Real) at /Users/joshday/.julia/v0.5/StatsBase/src/moments.jl:249
kurtosis(d::Distributions.Bernoulli) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/bernoulli.jl:27
kurtosis(d::Distributions.BetaBinomial) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/betabinomial.jl:39
kurtosis(d::Distributions.Binomial) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/binomial.jl:45
kurtosis(d::Distributions.Categorical) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/categorical.jl:77
kurtosis(d::Distributions.DiscreteUniform) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/discreteuniform.jl:39
kurtosis(d::Distributions.Geometric) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/geometric.jl:33
kurtosis(d::Distributions.Hypergeometric) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/hypergeometric.jl:50
kurtosis(d::Distributions.NegativeBinomial) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/negativebinomial.jl:40
kurtosis(d::Distributions.Poisson) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/poisson.jl:33
kurtosis(d::Distributions.Skellam) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/skellam.jl:28
kurtosis(d::Distributions.PoissonBinomial) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/poissonbinomial.jl:79
kurtosis(d::Distributions.Arcsine) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/arcsine.jl:28
kurtosis(d::Distributions.Beta) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/beta.jl:54
kurtosis(d::Distributions.Biweight) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/biweight.jl:22
kurtosis(d::Distributions.Cauchy) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/cauchy.jl:28
kurtosis(d::Distributions.Chisq) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/chisq.jl:23
kurtosis(d::Distributions.Chi) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/chi.jl:29
kurtosis(d::Distributions.Cosine) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/cosine.jl:38
kurtosis(d::Distributions.Epanechnikov) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/epanechnikov.jl:25
kurtosis(d::Distributions.Exponential) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/exponential.jl:27
kurtosis(d::Distributions.FDist) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/fdist.jl:40
kurtosis(d::Distributions.Frechet) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/frechet.jl:53
kurtosis(d::Distributions.Gamma) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/gamma.jl:36
kurtosis(d::Distributions.Erlang) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/erlang.jl:27
kurtosis(d::Distributions.GeneralizedPareto) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/generalizedpareto.jl:57
kurtosis(d::Distributions.GeneralizedExtremeValue) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/generalizedextremevalue.jl:85
kurtosis(d::Distributions.Gumbel) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/gumbel.jl:34
kurtosis(d::Distributions.InverseGamma) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/inversegamma.jl:43
kurtosis(d::Distributions.InverseGaussian) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/inversegaussian.jl:30
kurtosis(d::Distributions.Laplace) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/laplace.jl:31
kurtosis(d::Distributions.Levy) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/levy.jl:24
kurtosis(d::Distributions.Logistic) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/logistic.jl:30
kurtosis(d::Distributions.NoncentralChisq) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/noncentralchisq.jl:23
kurtosis(d::Distributions.Normal) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/normal.jl:29
kurtosis(d::Distributions.NormalCanon) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/normalcanon.jl:37
kurtosis(d::Distributions.LogNormal) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/lognormal.jl:40
kurtosis(d::Distributions.Pareto) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/pareto.jl:41
kurtosis(d::Distributions.Rayleigh) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/rayleigh.jl:27
kurtosis(d::Distributions.SymTriangularDist) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/symtriangular.jl:32
kurtosis(d::Distributions.TDist) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/tdist.jl:31
kurtosis(d::Distributions.TriangularDist) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/triangular.jl:50
kurtosis(d::Distributions.Triweight) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/triweight.jl:27
kurtosis(d::Distributions.Uniform) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/uniform.jl:30
kurtosis(d::Distributions.Weibull) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/weibull.jl:41
kurtosis(d::Distributions.EmpiricalUnivariateDistribution) at /Users/joshday/.julia/v0.5/Distributions/src/empirical.jl:38
kurtosis(d::Distributions.EdgeworthAbstract) at /Users/joshday/.julia/v0.5/Distributions/src/edgeworth.jl:10
kurtosis(d::Distributions.Distribution{F<:Distributions.VariateForm,S<:Distributions.ValueSupport}, correction::Bool) at /Users/joshday/.julia/v0.5/Distributions/src/univariates.jl:82
kurtosis(o::OnlineStats.Moments{W<:OnlineStats.Weight}) at /Users/joshday/.julia/v0.5/OnlineStats/src/summary.jl:354
```

[Top](#table-of-contents)
# loss
No documentation found.

`OnlineStats.loss` is a `Function`.

```
# 11 methods for generic function "loss":
loss(::OnlineStats.L2Regression, y, η) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:49
loss(::OnlineStats.L1Regression, y, η) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:50
loss(::OnlineStats.LogisticRegression, y, η) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:51
loss(::OnlineStats.PoissonRegression, y, η) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:52
loss(m::OnlineStats.QuantileRegression, y, η) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:53
loss(m::OnlineStats.SVMLike, y, η) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:55
loss(m::OnlineStats.HuberRegression, y, η) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:58
loss(o::OnlineStats.StatLearn{A<:OnlineStats.Algorithm,M<:OnlineStats.ModelDefinition,P<:OnlineStats.Penalty,W<:OnlineStats.Weight}, x::AbstractArray{T<:Any,2}, y::AbstractArray{T<:Any,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:219
loss(o::OnlineStats.StatLearnCV{T<:Real,S<:Real,W<:OnlineStats.Weight}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearnextensions.jl:143
loss(o::OnlineStats.StatLearnCV{T<:Real,S<:Real,W<:OnlineStats.Weight}, x, y) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearnextensions.jl:142
loss(o::OnlineStats.LinReg{W<:OnlineStats.Weight}, x::AbstractArray{Float64,2}, y::AbstractArray{Float64,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/linreg.jl:75
```

[Top](#table-of-contents)
# nobs
nobs(obj::StatisticalModel)

Returns the number of independent observations on which the model was fitted. Be careful when using this information, as the definition of an independent observation may vary depending on the model, on the format used to pass the data, on the sampling plan (if specified), etc.

[Top](#table-of-contents)
# predict
No documentation found.

`StatsBase.predict` is a `Function`.

```
# 14 methods for generic function "predict":
predict(obj::StatsBase.RegressionModel) at /Users/joshday/.julia/v0.5/StatsBase/src/statmodels.jl:153
predict(o::OnlineStats.L2Regression, x::AbstractArray{T<:Any,1}, β0, β) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:35
predict(o::OnlineStats.L1Regression, x::AbstractArray{T<:Any,1}, β0, β) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:36
predict(o::OnlineStats.LogisticRegression, x::AbstractArray{T<:Any,1}, β0, β) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:37
predict(o::OnlineStats.PoissonRegression, x::AbstractArray{T<:Any,1}, β0, β) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:38
predict(o::OnlineStats.QuantileRegression, x::AbstractArray{T<:Any,1}, β0, β) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:39
predict(o::OnlineStats.SVMLike, x::AbstractArray{T<:Any,1}, β0, β) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:40
predict(o::OnlineStats.HuberRegression, x::AbstractArray{T<:Any,1}, β0, β) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:41
predict{T<:Real}(o::OnlineStats.ModelDefinition, x::AbstractArray{T,2}, β0::Float64, β::Array{Float64,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:44
predict{T<:Real}(o::OnlineStats.StatLearn{A<:OnlineStats.Algorithm,M<:OnlineStats.ModelDefinition,P<:OnlineStats.Penalty,W<:OnlineStats.Weight}, x::AbstractArray{T,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:192
predict{T<:Real}(o::OnlineStats.StatLearn{A<:OnlineStats.Algorithm,M<:OnlineStats.ModelDefinition,P<:OnlineStats.Penalty,W<:OnlineStats.Weight}, x::AbstractArray{T,2}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:193
predict(o::OnlineStats.StatLearnCV{T<:Real,S<:Real,W<:OnlineStats.Weight}, x) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearnextensions.jl:141
predict{T<:Real}(o::OnlineStats.LinReg{W<:OnlineStats.Weight}, x::AbstractArray{T,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/linreg.jl:132
predict{T<:Real}(o::OnlineStats.LinReg{W<:OnlineStats.Weight}, x::AbstractArray{T,2}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/linreg.jl:133
```

[Top](#table-of-contents)
# replicates
No documentation found.

`OnlineStats.replicates` is a `Function`.

```
# 1 method for generic function "replicates":
replicates(b::OnlineStats.Bootstrap{I<:OnlineStats.Input}) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:143
```

[Top](#table-of-contents)
# skewness
No documentation found.

`StatsBase.skewness` is a `Function`.

```
# 53 methods for generic function "skewness":
skewness(v::AbstractArray{T<:Real,N<:Any}) at /Users/joshday/.julia/v0.5/StatsBase/src/moments.jl:228
skewness(v::AbstractArray{T<:Real,N<:Any}, m::Real) at /Users/joshday/.julia/v0.5/StatsBase/src/moments.jl:192
skewness(v::AbstractArray{T<:Real,N<:Any}, wv::StatsBase.WeightVec{W<:Any,Vec<:AbstractArray{T<:Real,1}}) at /Users/joshday/.julia/v0.5/StatsBase/src/moments.jl:229
skewness(v::AbstractArray{T<:Real,N<:Any}, wv::StatsBase.WeightVec{W<:Any,Vec<:AbstractArray{T<:Real,1}}, m::Real) at /Users/joshday/.julia/v0.5/StatsBase/src/moments.jl:208
skewness(d::Distributions.Bernoulli) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/bernoulli.jl:26
skewness(d::Distributions.BetaBinomial) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/betabinomial.jl:32
skewness(d::Distributions.Binomial) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/binomial.jl:39
skewness(d::Distributions.Categorical) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/categorical.jl:65
skewness(d::Distributions.DiscreteUniform) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/discreteuniform.jl:36
skewness(d::Distributions.Geometric) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/geometric.jl:31
skewness(d::Distributions.Hypergeometric) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/hypergeometric.jl:48
skewness(d::Distributions.NegativeBinomial) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/negativebinomial.jl:38
skewness(d::Distributions.Poisson) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/poisson.jl:31
skewness(d::Distributions.Skellam) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/skellam.jl:26
skewness(d::Distributions.PoissonBinomial) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/poissonbinomial.jl:68
skewness(d::Distributions.Arcsine) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/arcsine.jl:27
skewness(d::Distributions.Beta) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/beta.jl:44
skewness(d::Distributions.BetaPrime) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/betaprime.jl:32
skewness(d::Distributions.Biweight) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/biweight.jl:21
skewness(d::Distributions.Cauchy) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/cauchy.jl:27
skewness(d::Distributions.Chisq) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/chisq.jl:21
skewness(d::Distributions.Chi) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/chi.jl:23
skewness(d::Distributions.Cosine) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/cosine.jl:36
skewness(d::Distributions.Epanechnikov) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/epanechnikov.jl:24
skewness(d::Distributions.Exponential) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/exponential.jl:26
skewness(d::Distributions.FDist) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/fdist.jl:31
skewness(d::Distributions.Frechet) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/frechet.jl:41
skewness(d::Distributions.Gamma) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/gamma.jl:34
skewness(d::Distributions.Erlang) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/erlang.jl:26
skewness(d::Distributions.GeneralizedPareto) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/generalizedpareto.jl:47
skewness(d::Distributions.GeneralizedExtremeValue) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/generalizedextremevalue.jl:72
skewness(d::Distributions.Gumbel) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/gumbel.jl:32
skewness(d::Distributions.InverseGamma) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/inversegamma.jl:38
skewness(d::Distributions.InverseGaussian) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/inversegaussian.jl:28
skewness(d::Distributions.Laplace) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/laplace.jl:30
skewness(d::Distributions.Levy) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/levy.jl:23
skewness(d::Distributions.Logistic) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/logistic.jl:29
skewness(d::Distributions.NoncentralChisq) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/noncentralchisq.jl:22
skewness(d::Distributions.Normal) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/normal.jl:28
skewness(d::Distributions.NormalCanon) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/normalcanon.jl:36
skewness(d::Distributions.NormalInverseGaussian) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/normalinversegaussian.jl:18
skewness(d::Distributions.LogNormal) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/lognormal.jl:34
skewness(d::Distributions.Pareto) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/pareto.jl:36
skewness(d::Distributions.Rayleigh) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/rayleigh.jl:26
skewness(d::Distributions.SymTriangularDist) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/symtriangular.jl:31
skewness(d::Distributions.TDist) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/tdist.jl:28
skewness(d::Distributions.TriangularDist) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/triangular.jl:46
skewness(d::Distributions.Triweight) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/triweight.jl:26
skewness(d::Distributions.Uniform) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/uniform.jl:29
skewness(d::Distributions.Weibull) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/weibull.jl:33
skewness(d::Distributions.EmpiricalUnivariateDistribution) at /Users/joshday/.julia/v0.5/Distributions/src/empirical.jl:46
skewness(d::Distributions.EdgeworthAbstract) at /Users/joshday/.julia/v0.5/Distributions/src/edgeworth.jl:9
skewness(o::OnlineStats.Moments{W<:OnlineStats.Weight}) at /Users/joshday/.julia/v0.5/OnlineStats/src/summary.jl:350
```

[Top](#table-of-contents)
# standardize
No documentation found.

`OnlineStats.standardize` is a `Function`.

```
# 2 methods for generic function "standardize":
standardize(o::OnlineStats.Variance{W<:OnlineStats.Weight}, x::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/summary.jl:79
standardize{T<:Real}(o::OnlineStats.Variances{W<:OnlineStats.Weight}, x::AbstractArray{T,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/summary.jl:122
```

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
