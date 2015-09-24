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

# SGModel
See the [Stochastic Gradient Methods](Stochastic Gradient Methods.md) topic.
This is a powerful type that fits a variety of models using a variety of
online algorithms.  There are also several regularization options.

```julia
o = SGModel(x, y, model = L2Regression(), algorithm = RDA(), penalty = L1Penalty(.1))
coef(o)
predict(o, x)
```

# SparseReg
Analytical regularized regression.  Currently supports least squares, ridge
regression, LASSO, and elastic net.  

```julia
o = SparseReg(x, y)
coef(o)                             # Least squres
coef(o, L2Penalty(λ))               # Ridge
coef(o, L1Penalty(λ))               # LASSO
coef(o, ElasticNetPenalty(λ, α))    # α * lasso_penalty + (1 - α) * ridge_penalty
coef(o, ElasticNetPenalty(λ, 0.0))  # Ridge
coef(o, ElasticNetPenalty(λ, 1.0))  # LASSO
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
