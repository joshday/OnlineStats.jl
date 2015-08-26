<!-- TOC depth:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Adagrad](#adagrad)
- [Bootstrap](#bootstrap)
- [CovarianceMatrix](#covariancematrix)
- [Diff](#diff)
- [Diffs](#diffs)
- [FiveNumberSummary](#fivenumbersummary)
- [HyperLogLog](#hyperloglog)
- [LinReg](#linreg)
- [Mean](#mean)
- [Means](#means)
- [Moments](#moments)
- [Momentum](#momentum)
- [NormalMix](#normalmix)
- [Principal Components Analysis (no dedicated type)](#principal-components-analysis-no-dedicated-type)
- [SGD](#sgd)
- [SparseReg](#sparsereg)
- [StepwiseReg](#stepwisereg)
- [Summary](#summary)
- [QuantileMM](#quantilemm)
- [QuantRegMM](#quantregmm)
- [Variance](#variance)
- [Variances](#variances)
- [Fitting a Parametric Distribution](#fitting-a-parametric-distribution)
<!-- /TOC -->

In the given examples, `y` is typically an n by 1 `Vector{Float64}` and `x` is usually an n by p `Matrix{Float64}`.  

Each type has it's own `state` and `statenames` methods.

# Adagrad
Stochastic adaptive gradient descent for a given model.  See the Stochastic Gradient Methods topic.  Adagrad does not use a weighting scheme as weights are adaptively chosen.

```julia
o = Adagrad(x, y, model = L1Regression(), penalty = L2Penalty())
coef(o)
predict(o, x)
```

# Bootstrap
Statistical bootstrap for estimating the variance of an OnlineStat.

- BernoulliBootstrap
- PoissonBootstrap

```julia
o = Mean()
boot = BernoulliBootstrap(o, mean, 1000)
update!(boot, x)
```

# CovarianceMatrix
Analytical covariance matrix.

```julia
o = CovarianceMatrix(x)
mean(o)  # vec(mean(x, 1))
cov(o)   # cov(x)
cor(o)   # cor(x)
pca(o)   # MultivariateStats.fit(PCA, x)
```

# Diff
Track the last value and last difference.

# Diffs
Track the last value and last difference for several variables.

# FiveNumberSummary
Univariate five number summary using exact maximum/minimum and approximate .25, .5, and .75 quantiles.

```julia
o = FiveNumberSummary(x)
minimum(o)
maximum(o)
state(o)
```

# HyperLogLog
Experimental implementation of hyperloglog algorithm.

# LinReg
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

# Mean
Analytical sample mean.

```julia
o = Mean(y)
mean(o)
```

# Means
Analytical sample means, similar to `mean(x, 1)`.

```julia
o = Means(x)
mean(o)  # vec(mean(x, 1))
```

# Moments
First four non-central moments.  Tracks mean, variance, skewness, and kurtosis.

```julia
o = Moments(y)
mean(o)
var(o)
std(o)
skewness(o)
kurtosis(o)
```

# Momentum
Stochastic gradient descent with momentum for a given model.  See the Stochastic Gradient Methods topic.

```julia
o = Momentum(x, y)
coef(o)
predict(o, x)
```

# NormalMix
Univariate normal mixture via an online EM algorithm.

```julia
o = NormalMix(4, y, StochasticWeighting(.6))
mean(o)
var(o)
std(o)
quantile(o, .8)
```

# Principal Components Analysis (no dedicated type)
Use `pca(o::CovarianceMatrix, maxoutdim = k)`.  The keyword argument `maxoutdim` specifies
the top `k` components to return.

# SGD
Stochastic gradient descent for a given model.  See the Stochastic Gradient Methods topic.

```julia
o = SGD(x, y, model = L2Regression())
coef(o)
predict(o, x)
```

# SparseReg
Analytical regularized regression.  Currently supports ordinary least squares, ridge
regression, LASSO, and elastic net.

```julia
o = SparseReg(x, y)
coef(o)
coef(o, :ridge, λ)
coef(o, :lasso, λ)
coef(o, :elasticnet, λ, α)
coef(o, :elasticnet, λ, 0.0)  # Ridge
coef(o, :elasticnet, λ, 1.0)  # LASSO
```

# StepwiseReg
Experimental stepwise regression.  With each update, there is the possibility of a variable entering or leaving the model.

```julia
o = StepwiseReg(size(x, 2))
onlinefit!(o, batchsize, x, y)
coef(o)
```

# Summary
Summary statistics: mean, variance, maximum, and minimum.

```julia
o = Summary(y)
mean(o)
var(o)
std(o)
maximum(o)
minimum(o)
```

# QuantileMM
Approximate quantiles using an online MM algorithm.

```julia
o = QuantileMM(y, [.25, .5, .75], StochasticWeighting(.51))
statenames(o)
state(o)
```

# QuantRegMM
Approximate quantile regression using an online MM algorithm.

```julia
o = QuantRegMM(size(x, 2), τ = .7)
onlinefit!(o, batchsize, x, y)
coef(o)
```

# Variance
Analytical sample variance.

```julia
o = Variance(y)
mean(o)
var(o)
std(o)
```

# Variances
Analytical sample variances, similar to `var(x, 1)`.

```julia
o = Variances(x)
mean(o)  # vec(mean(x, 1))
var(o)   # vec(var(x, 1))
std(o)   # vec(std(x, 1))
```

# Fitting a Parametric Distribution
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
