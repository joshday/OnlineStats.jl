# Models

In the examples below, assume y is `Vector{Float64}` and x is `Matrix{Float64}`

<!-- TOC depth:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Models](#models)
	- [Bootstrap: BernoulliBootstrap and PoissonBootstrap](#bootstrap-bernoullibootstrap-and-poissonbootstrap)
	- [CovarianceMatrix](#covariancematrix)
	- [Diff](#diff)
	- [Diffs](#diffs)
	- [FiveNumberSummary](#fivenumbersummary)
	- [HyperLogLog](#hyperloglog)
	- [LinReg](#linreg)
	- [Mean](#mean)
	- [Means](#means)
	- [Moments](#moments)
	- [NormalMix](#normalmix)
	- [Principal Components Analysis](#principal-components-analysis)
	- [SGModel](#sgmodel)
	- [SGModelTune](#sgmodeltune)
	- [ShermanMorrisonInverse](#shermanmorrisoninverse)
	- [SparseReg](#sparsereg)
	- [StepwiseReg](#stepwisereg)
	- [Summary](#summary)
	- [QuantileMM](#quantilemm)
	- [QuantRegMM](#quantregmm)
	- [Variance](#variance)
	- [Variances](#variances)
	- [Fitting a Parametric Distribution](#fitting-a-parametric-distribution)
<!-- /TOC -->

## Bootstrap: BernoulliBootstrap and PoissonBootstrap
Statistical bootstrap for estimating the variance of an OnlineStat.

```julia
o = Mean()
boot = BernoulliBootstrap(o, mean, 1000)
update!(boot, y)
```

## CovarianceMatrix
Analytical covariance matrix.

```julia
o = CovarianceMatrix(x)
mean(o)  # vec(mean(x, 1))
cov(o)   # cov(x)
cor(o)   # cor(x)
pca(o)   # MultivariateStats.fit(PCA, x)
```

## Diff
Track the last value and last difference.

## Diffs
Track the last value and last difference for several variables.

## FiveNumberSummary
Univariate five number summary using exact maximum/minimum and approximate .25, .5, and .75 quantiles.

```julia
o = FiveNumberSummary(x)
minimum(o)
maximum(o)
state(o)
```

## HyperLogLog
Experimental implementation of hyperloglog algorithm.

## LinReg
Analytical linear regression.

```julia
o = LinReg(x, y)
updatebatch!(x2, y2)

coef(o)
coeftable(o)
stderr(o)
vcov(o)
predict(o, x)
```

## Mean
Analytical sample mean.

```julia
o = Mean(y)
mean(o)
```

## Means
Analytical sample means, similar to `mean(x, 1)`.

```julia
o = Means(x)
mean(o)  # vec(mean(x, 1))
```

## Moments
First four non-central moments.  Tracks mean, variance, skewness, and kurtosis.

```julia
o = Moments(y)
mean(o)
var(o)
std(o)
skewness(o)
kurtosis(o)
```

## NormalMix
Univariate normal mixture via an online EM algorithm.

```julia
o = NormalMix(4, y, LearningRate(r = .6))
mean(o)
var(o)
std(o)
quantile(o, .8)
```

## Principal Components Analysis
Use `pca(o::CovarianceMatrix, maxoutdim = k)`.  The keyword argument `maxoutdim` specifies
the top `k` components to return.


## SGModel
This is a flexible type that fits a wide variety of models using three different
online algorithms (`SGD`, `ProxGrad`, and `RDA`).  Each algorithm uses stochastic
estimates of the (sub)gradient of the loss function.  Models available are :

- `HuberRegression(δ)`
- `L1Regression()`
- `L2Regression()`
- `LogisticRegression()`
- `PoissonRegression()`
- `QuantileRegression(τ)`
- `SVMLike` (Perceptron and Suppert Vector Machine)

```julia
o = SGModel(x, y, model = L2Regression(), algorithm = RDA(), penalty = L1Penalty(.1))
coef(o)
predict(o, x)
```
See the section on [Stochastic Subgradient Models](SGModel.md).

## SGModelTune
Takes an SGModel and automatically fits the optimal tuning parameter.

```julia
o = SGModel(size(x, 2))
otune = SGModelTune(o)
update!(otune, x, y)
```

See the section on [Stochastic Subgradient Models](SGModel.md).


## ShermanMorrisonInverse

Use the [Sherman-Morrison formula](https://en.wikipedia.org/wiki/Sherman–Morrison_formula)
for updating the matrix `inv(x'x / n)`.  

```julia
o = ShermanMorrisonInverse(x)
```

## SparseReg
Analytical regularized regression.  This type collects sufficient statistics.  At
any point in time, regularized coefficients can be returned using a variety of
penalties.  Currently supports least squares, ridge regression, LASSO, elastic net,
and SCAD coefficients.

$$\ell(\boldsymbol\beta) = \|\mathbf y - \mathbf X^T \boldsymbol \beta\| + λ J(\boldsymbol\beta)$$  

```julia
o = SparseReg(x, y)
coef(o)                             # Least squres
coef(o, L2Penalty(λ))               # Ridge
coef(o, L1Penalty(λ))               # LASSO
coef(o, ElasticNetPenalty(λ, α))    # α * lasso_penalty + (1 - α) * ridge_penalty
coef(o, SCADPenalty(λ, a))          # SCAD
```

## StepwiseReg
Experimental stepwise regression.  With each update, there is the possibility of a variable entering or leaving the model.

```julia
o = StepwiseReg(size(x, 2))
onlinefit!(o, batchsize, x, y)
coef(o)
```

## Summary
Summary statistics: mean, variance, maximum, and minimum.

```julia
o = Summary(y)
mean(o)
var(o)
std(o)
maximum(o)
minimum(o)
```

## QuantileMM
Approximate quantiles using an online MM algorithm.

```julia
o = QuantileMM(y, [.25, .5, .75], LearningRate(r = .51))
statenames(o)
state(o)
```

## QuantRegMM
Approximate quantile regression using an online MM algorithm.

```julia
o = QuantRegMM(size(x, 2), τ = .7)
onlinefit!(o, batchsize, x, y)
coef(o)
```

## QuantileSGD
Approximate quantiles using a stochastic (sub)gradient descent algorithm

```julia
o = QuantileSGD(y, [.25, .5, .75], LearningRate(r = .7))
statenames(o)
state(o)
```

## Variance
Analytical sample variance.

```julia
o = Variance(y)
mean(o)
var(o)
std(o)
```

## Variances
Analytical sample variances, similar to `var(x, 1)`.

```julia
o = Variances(x)
mean(o)  # vec(mean(x, 1))
var(o)   # vec(var(x, 1))
std(o)   # vec(std(x, 1))
```

## Fitting a Parametric Distribution
Estimating the parameters of a distribution in an online setting can be done using ```distributionfit(Dist, y, args...)``` where `Dist` is one of the following:

- `Bernoulli`
- `Beta`
- `Binomial`
- `Cauchy`
- `Dirichlet`
- `Exponential`
- `Gamma`
- `LogNormal`
- `Multinomial`
- `MvNormal`
- `Normal`
- `Poisson`

To ensure a consistent interface for OnlineStats, fitting a multivariate distribution requires observations to be in rows.  This differs from fitting multivariate distributions in the Distributions package.
