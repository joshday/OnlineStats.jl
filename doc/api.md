<!--- Generated at 2016-09-23T10:39:52.839.  Don't edit --->
# API

## ADAM
No documentation found.

**Summary:**

```
immutable OnlineStats.ADAM <: OnlineStats.Algorithm
```

**Fields:**

```
m1 :: Float64
m2 :: Float64
```

## AdaDelta
No documentation found.

**Summary:**

```
immutable OnlineStats.AdaDelta <: OnlineStats.Algorithm
```

**Fields:**

```
ρ :: Float64
```

## AdaGrad
No documentation found.

**Summary:**

```
immutable OnlineStats.AdaGrad <: OnlineStats.Algorithm
```

## AdaGrad2
No documentation found.

**Summary:**

```
immutable OnlineStats.AdaGrad2 <: OnlineStats.Algorithm
```

## Algorithm
No documentation found.

**Summary:**

```
abstract OnlineStats.Algorithm <: Any
```

**Subtypes:**

```
OnlineStats.ADAM
OnlineStats.AdaDelta
OnlineStats.AdaGrad
OnlineStats.AdaGrad2
OnlineStats.Momentum
OnlineStats.SGD
```

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

## ElasticNetPenalty
No documentation found.

**Summary:**

```
immutable OnlineStats.ElasticNetPenalty <: OnlineStats.Penalty
```

**Fields:**

```
λ :: Float64
a :: Float64
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

## FitBeta
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

## FitCategorical
Find the proportions for each unique input.  Categories are sorted by proportions. Ignores `Weight`.

```julia
o = FitCategorical(y)
```

## FitCauchy
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

## FitGamma
No documentation found.

**Summary:**

```
type OnlineStats.FitGamma{W<:OnlineStats.Weight} <: OnlineStats.DistributionStat{OnlineStats.ScalarInput}
```

**Fields:**

```
value :: Distributions.Gamma{T<:Real}
var   :: OnlineStats.Variance{W<:OnlineStats.Weight}
```

## FitLogNormal
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

## FitMultinomial
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

## FitMvNormal
No documentation found.

**Summary:**

```
type OnlineStats.FitMvNormal{W<:OnlineStats.Weight} <: OnlineStats.DistributionStat{OnlineStats.VectorInput}
```

**Fields:**

```
value :: Distributions.MvNormal{T<:Real,Cov<:PDMats.AbstractPDMat,Mean<:Union{Array{T,1},Distributions.ZeroVector}}
cov   :: OnlineStats.CovMatrix{W<:OnlineStats.Weight}
```

## FitNormal
No documentation found.

**Summary:**

```
type OnlineStats.FitNormal{W<:OnlineStats.Weight} <: OnlineStats.DistributionStat{OnlineStats.ScalarInput}
```

**Fields:**

```
value :: Distributions.Normal{T<:Real}
var   :: OnlineStats.Variance{W<:OnlineStats.Weight}
```

## FrozenBootstrap
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

## HuberRegression
No documentation found.

**Summary:**

```
immutable OnlineStats.HuberRegression <: OnlineStats.Model
```

**Fields:**

```
δ :: Float64
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

## L1Regression
No documentation found.

**Summary:**

```
immutable OnlineStats.L1Regression <: OnlineStats.Model
```

## LassoPenalty
No documentation found.

**Summary:**

```
immutable OnlineStats.LassoPenalty <: OnlineStats.Penalty
```

**Fields:**

```
λ :: Float64
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

## LinearRegression
No documentation found.

**Summary:**

```
immutable OnlineStats.LinearRegression <: OnlineStats.Model
```

## LogRegMM
No documentation found.

**Summary:**

```
type OnlineStats.LogRegMM{W<:OnlineStats.Weight} <: OnlineStats.OnlineStat{OnlineStats.XYInput}
```

**Fields:**

```
β      :: Array{Float64,1}
H      :: Array{Float64,2}
A      :: Array{Float64,2}
b      :: Array{Float64,1}
weight :: W<:OnlineStats.Weight
```

## LogisticRegression
For data in {0, 1}

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

## Model
No documentation found.

**Summary:**

```
abstract OnlineStats.Model <: Any
```

**Subtypes:**

```
OnlineStats.BivariateModel
OnlineStats.HuberRegression
OnlineStats.L1Regression
OnlineStats.LinearRegression
OnlineStats.PoissonRegression
OnlineStats.QuantileRegression
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

## NoPenalty
No documentation found.

**Summary:**

```
immutable OnlineStats.NoPenalty <: OnlineStats.Penalty
```

## NormalMix
Normal Mixture of `k` components via an online EM algorithm.  `start` is a keyword argument specifying the initial parameters.

```julia
o = NormalMix(2, LearningRate(); start = MixtureModel(Normal, [(0, 1), (3, 1)]))
mean(o)
var(o)
std(o)
```

## OnlineStat
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
OnlineStats.LogRegMM{W<:OnlineStats.Weight}
OnlineStats.Means{W<:OnlineStats.Weight}
OnlineStats.Mean{W<:OnlineStats.Weight}
OnlineStats.Moments{W<:OnlineStats.Weight}
OnlineStats.QuantRegMM{W<:OnlineStats.Weight}
OnlineStats.QuantileMM{W<:OnlineStats.Weight}
OnlineStats.QuantileSGD{W<:OnlineStats.StochasticWeight}
OnlineStats.StatLearn{A<:OnlineStats.Algorithm,M<:OnlineStats.Model,P<:OnlineStats.Penalty,W<:OnlineStats.StochasticWeight}
OnlineStats.Sums{T<:Real}
OnlineStats.Sum{T<:Real}
OnlineStats.Variances{W<:OnlineStats.Weight}
OnlineStats.Variance{W<:OnlineStats.Weight}
```

## Penalty
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
```

## PoissonBootstrap
No documentation found.

`OnlineStats.PoissonBootstrap` is a `Function`.

```
# 4 methods for generic function "PoissonBootstrap":
PoissonBootstrap{T<:OnlineStats.ScalarInput}(o::OnlineStats.OnlineStat{T}, f::Function) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:63
PoissonBootstrap{T<:OnlineStats.ScalarInput}(o::OnlineStats.OnlineStat{T}, f::Function, r::Int64) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:63
PoissonBootstrap{T<:OnlineStats.VectorInput}(o::OnlineStats.OnlineStat{T}, f::Function) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:76
PoissonBootstrap{T<:OnlineStats.VectorInput}(o::OnlineStats.OnlineStat{T}, f::Function, r::Int64) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:76
```

## PoissonRegression
No documentation found.

**Summary:**

```
immutable OnlineStats.PoissonRegression <: OnlineStats.Model
```

## QuantRegMM
Online MM Algorithm for Quantile Regression.

## QuantileMM
Approximate quantiles via an online MM algorithm.  Typically more accurate than `QuantileSGD`.

```julia
o = QuantileMM(y, LearningRate())
o = QuantileMM(y, tau = [.25, .5, .75])
fit!(o, y2)
```

## QuantileRegression
No documentation found.

**Summary:**

```
immutable OnlineStats.QuantileRegression <: OnlineStats.Model
```

**Fields:**

```
τ :: Float64
```

## QuantileSGD
Approximate quantiles via stochastic gradient descent.

```julia
o = QuantileSGD(y, LearningRate())
o = QuantileSGD(y, tau = [.25, .5, .75])
fit!(o, y2)
```

## RidgePenalty
No documentation found.

**Summary:**

```
immutable OnlineStats.RidgePenalty <: OnlineStats.Penalty
```

**Fields:**

```
λ :: Float64
```

## SGD
No documentation found.

**Summary:**

```
immutable OnlineStats.SGD <: OnlineStats.Algorithm
```

## SVMLike
For data in {-1, 1}

## StatLearn
No documentation found.

**Summary:**

```
type OnlineStats.StatLearn{A<:OnlineStats.Algorithm,M<:OnlineStats.Model,P<:OnlineStats.Penalty,W<:OnlineStats.StochasticWeight} <: OnlineStats.OnlineStat{OnlineStats.XYInput}
```

**Fields:**

```
β0        :: Float64
β         :: Array{Float64,1}
intercept :: Bool
η         :: Float64
H0        :: Float64
G0        :: Float64
H         :: Array{Float64,1}
G         :: Array{Float64,1}
algorithm :: A<:OnlineStats.Algorithm
model     :: M<:OnlineStats.Model
penalty   :: P<:OnlineStats.Penalty
weight    :: W<:OnlineStats.StochasticWeight
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

  * `TwoWayInteractionMatrix(rand(n, p))` "adds" the `binomial(p, 2)` interaction terms

to each row

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

## Weight
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

## cached_state
No documentation found.

`OnlineStats.cached_state` is a `Function`.

```
# 3 methods for generic function "cached_state":
cached_state(b::OnlineStats.FrozenBootstrap) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:103
cached_state(b::OnlineStats.Bootstrap{OnlineStats.ScalarInput}) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:116
cached_state(b::OnlineStats.Bootstrap{OnlineStats.VectorInput}) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:125
```

## center
No documentation found.

`OnlineStats.center` is a `Function`.

```
# 4 methods for generic function "center":
center(o::OnlineStats.Mean, x::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/summary.jl:24
center{T<:Real}(o::OnlineStats.Means, x::AbstractArray{T,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/summary.jl:49
center(o::OnlineStats.Variance, x::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/summary.jl:80
center{T<:Real}(o::OnlineStats.Variances, x::AbstractArray{T,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/summary.jl:126
```

## classify
No documentation found.

`OnlineStats.classify` is a `Function`.

```
# 4 methods for generic function "classify":
classify(m::OnlineStats.BivariateModel, η::Array{T<:Any,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:45
classify(m::OnlineStats.LogisticRegression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:69
classify(m::OnlineStats.SVMLike, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:99
classify(o::OnlineStats.StatLearn, x) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:81
```

## coef
No documentation found.

`StatsBase.coef` is a `Function`.

```
# 9 methods for generic function "coef":
coef(obj::StatsBase.StatisticalModel) at /Users/joshday/.julia/v0.5/StatsBase/src/statmodels.jl:5
coef(o::OnlineStats.StatLearn) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:79
coef(o::OnlineStats.LinReg) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/linreg.jl:65
coef(o::OnlineStats.LogRegMM) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/logregmm.jl:40
coef(o::OnlineStats.QuantRegMM) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/quantregmm.jl:19
coef(o::OnlineStats.StatLearn) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:79
coef(o::OnlineStats.LinReg) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/linreg.jl:65
coef(o::OnlineStats.LogRegMM) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/logregmm.jl:40
coef(o::OnlineStats.QuantRegMM) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/quantregmm.jl:19
```

## cost
No documentation found.

`OnlineStats.cost` is a `Function`.

```
# 2 methods for generic function "cost":
cost(o::OnlineStats.StatLearn, x::AbstractArray{T<:Any,1}, y::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:88
cost(o::OnlineStats.StatLearn, x::AbstractArray{T<:Any,2}, y::AbstractArray{T<:Any,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:89
```

## fit
No documentation found.

`StatsBase.fit` is a `Function`.

```
# 17 methods for generic function "fit":
fit(::Type{Distributions.Binomial}, data::Tuple{Int64,AbstractArray}) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/binomial.jl:191
fit(::Type{Distributions.Binomial}, data::Tuple{Int64,AbstractArray}, w::AbstractArray{Float64,N<:Any}) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/binomial.jl:192
fit(::Type{Distributions.Categorical}, data::Tuple{Int64,AbstractArray}) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/categorical.jl:272
fit(::Type{Distributions.Categorical}, data::Tuple{Int64,AbstractArray}, w::AbstractArray{Float64,N<:Any}) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/discrete/categorical.jl:273
fit{T<:Real}(::Type{Distributions.Beta}, x::AbstractArray{T,N<:Any}) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/beta.jl:114
fit{T<:Real}(::Type{Distributions.Cauchy}, x::AbstractArray{T,N<:Any}) at /Users/joshday/.julia/v0.5/Distributions/src/univariate/continuous/cauchy.jl:91
fit(::Type{StatsBase.Histogram}, v::AbstractArray{T<:Any,1}; closed, nbins) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:165
fit(::Type{StatsBase.Histogram}, v::AbstractArray{T<:Any,1}, edg::AbstractArray{T<:Any,1}; closed) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:163
fit(::Type{StatsBase.Histogram}, v::AbstractArray{T<:Any,1}, wv::StatsBase.WeightVec; closed, nbins) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:170
fit{W}(::Type{StatsBase.Histogram}, v::AbstractArray{T<:Any,1}, wv::StatsBase.WeightVec{W,Vec<:AbstractArray{T<:Real,1}}, edg::AbstractArray{T<:Any,1}; closed) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:168
fit{N}(::Type{StatsBase.Histogram}, vs::Tuple{Vararg{AbstractArray{T<:Any,1},N}}, edges::Tuple{Vararg{AbstractArray{T<:Any,1},N}}; closed) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:202
fit{N}(::Type{StatsBase.Histogram}, vs::Tuple{Vararg{AbstractArray{T<:Any,1},N}}; closed, nbins) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:204
fit{N}(::Type{StatsBase.Histogram}, vs::Tuple{Vararg{AbstractArray{T<:Any,1},N}}, wv::StatsBase.WeightVec; closed, nbins) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:209
fit{N,W}(::Type{StatsBase.Histogram}, vs::Tuple{Vararg{AbstractArray{T<:Any,1},N}}, wv::StatsBase.WeightVec{W,Vec<:AbstractArray{T<:Real,1}}, edges::Tuple{Vararg{AbstractArray{T<:Any,1},N}}; closed) at /Users/joshday/.julia/v0.5/StatsBase/src/hist.jl:207
fit(obj::StatsBase.StatisticalModel, data...) at /Users/joshday/.julia/v0.5/StatsBase/src/statmodels.jl:46
fit{D<:Distributions.Distribution{F<:Distributions.VariateForm,S<:Distributions.ValueSupport}}(dt::Type{D}, x) at /Users/joshday/.julia/v0.5/Distributions/src/genericfit.jl:14
fit{D<:Distributions.Distribution{F<:Distributions.VariateForm,S<:Distributions.ValueSupport}}(dt::Type{D}, args...) at /Users/joshday/.julia/v0.5/Distributions/src/genericfit.jl:15
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

## kurtosis
```
kurtosis(v, [wv::WeightVec], m=mean(v))
```

Compute the excess kurtosis of a real-valued array `v`, optionally specifying a weighting vector `wv` and a center `m`.

## loss
No documentation found.

`OnlineStats.loss` is a `Function`.

```
# 12 methods for generic function "loss":
loss(m::OnlineStats.Model, y::Array{T<:Any,1}, η::Array{T<:Any,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:25
loss(m::OnlineStats.LinearRegression, y::Real, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:53
loss(m::OnlineStats.L1Regression, y::Real, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:59
loss(m::OnlineStats.LogisticRegression, y::Real, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:66
loss(m::OnlineStats.PoissonRegression, y::Real, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:89
loss(m::OnlineStats.SVMLike, y::Real, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:96
loss(m::OnlineStats.QuantileRegression, y::Real, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:104
loss(m::OnlineStats.HuberRegression, y::Real, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:113
loss(o::OnlineStats.StatLearn, x::AbstractArray{T<:Any,1}, y::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:86
loss(o::OnlineStats.StatLearn, x::AbstractArray{T<:Any,2}, y::AbstractArray{T<:Any,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:87
loss(o::OnlineStats.LinReg, x, y) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/linreg.jl:115
loss(o::OnlineStats.LogRegMM, x, y) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/logregmm.jl:44
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
```
nobs(obj::StatisticalModel)
```

Returns the number of independent observations on which the model was fitted. Be careful when using this information, as the definition of an independent observation may vary depending on the model, on the format used to pass the data, on the sampling plan (if specified), etc.

## predict
No documentation found.

`StatsBase.predict` is a `Function`.

```
# 25 methods for generic function "predict":
predict(m::OnlineStats.LinearRegression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:55
predict(m::OnlineStats.L1Regression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:61
predict(m::OnlineStats.LogisticRegression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:68
predict(m::OnlineStats.PoissonRegression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:91
predict(m::OnlineStats.SVMLike, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:98
predict(m::OnlineStats.QuantileRegression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:108
predict(m::OnlineStats.HuberRegression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:120
predict(m::OnlineStats.LinearRegression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:55
predict(m::OnlineStats.L1Regression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:61
predict(m::OnlineStats.LogisticRegression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:68
predict(m::OnlineStats.PoissonRegression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:91
predict(m::OnlineStats.SVMLike, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:98
predict(m::OnlineStats.QuantileRegression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:108
predict(m::OnlineStats.HuberRegression, η::Real) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:120
predict(obj::StatsBase.RegressionModel) at /Users/joshday/.julia/v0.5/StatsBase/src/statmodels.jl:153
predict(m::OnlineStats.Model, η::Array{T<:Any,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:35
predict(o::OnlineStats.StatLearn, x) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:80
predict(o::OnlineStats.LinReg, x::AbstractArray{T<:Any,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/linreg.jl:103
predict(o::OnlineStats.LinReg, x::AbstractArray{T<:Any,2}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/linreg.jl:105
predict(o::OnlineStats.LogRegMM, x) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/logregmm.jl:43
predict(m::OnlineStats.Model, η::Array{T<:Any,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/temp.jl:35
predict(o::OnlineStats.StatLearn, x) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/statlearn.jl:80
predict(o::OnlineStats.LinReg, x::AbstractArray{T<:Any,1}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/linreg.jl:103
predict(o::OnlineStats.LinReg, x::AbstractArray{T<:Any,2}) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/linreg.jl:105
predict(o::OnlineStats.LogRegMM, x) at /Users/joshday/.julia/v0.5/OnlineStats/src/modeling/logregmm.jl:43
```

## replicates
No documentation found.

`OnlineStats.replicates` is a `Function`.

```
# 1 method for generic function "replicates":
replicates(b::OnlineStats.Bootstrap) at /Users/joshday/.julia/v0.5/OnlineStats/src/streamstats/bootstrap.jl:143
```

## skewness
```
skewness(v, [wv::WeightVec], m=mean(v))
```

Compute the standardized skewness of a real-valued array `v`, optionally specifying a weighting vector `wv` and a center `m`.

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

