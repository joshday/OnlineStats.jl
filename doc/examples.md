# Available Statistics and Models

### BernoulliBootstrap
Double-or-nothing statistical bootstrap for estimating variance of an OnlineStat.
```julia
o = Mean()
b = BernoulliBootstrap(o, mean, 1000)
fit!(b, y)  # updates b and o
```

### CovMatrix
Covariance Matrix.  
```julia
o = CovMatrix(x, EqualWeight())
cov(o)
cor(o)
var(o)
std(o)
mean(o)
```


### Extrema
Maximum and minimum of univariate data.
```julia
o = Extrema(y)
extrema(o)
```


### FitDistribution
Estimate parameters of a univariate distribution.
```julia
o = FitDistribution(Bernoulli, y)
o = FitDistribution(Beta, y)
o = FitDistribution(Categorical, y)
o = FitDistribution(Cauchy, y)
o = FitDistribution(Exponential, y)
o = FitDistribution(Gamma, y)
o = FitDistribution(LogNormal, y)
o = FitDistribution(Normal, y)
o = FitDistribution(Poisson, y)
mean(o)
var(o)
std(o)
params(o)
```


### FitMvDistribution
Estimate parameters of a multivariate distribution.
```julia
o = FitMvDistribution(Multinomial, x)
o = FitMvDistribution(MvNormal, x)
mean(o)
var(o)
std(o)
cov(o)
```


### KMeans
K-Means clustering of multivariate data
```julia
o = KMeans(x, k)
value(o)
```


### LinReg
Linear regression with optional regularization.
```julia
o = LinReg(x, y)
coef(o)
coef(o, λ, L2Penalty())  # Ridge
coef(o, λ, L1Penalty())  # LASSO
coef(o, λ, ElasticNetPenalty())
coef(o, λ, SCADPenalty())
predict(o, x)
```


### Mean
Univariate mean.
```julia
o = Mean(y)
mean(o)
```


### Means
Means of multiple series.
```julia
o = Means(x)
mean(o)
```


### Moments
First four moments of univariate data.
```julia
o = Moments(y)
mean(o)
var(o)
std(o)
skewness(o)
kurtosis(o)
```


### QuantileSGD
Approximate quantiles via stochastic gradient descent.
```julia
o = QuantileSGD(y, tau = [.25, .5, .75])
value(o)
```


### QuantileMM
Approximate quantiles via an online MM algorithm.  Typically more accurate
than `QuantileSGD`.
```julia
o = QuantileMM(y, tau = [.25, .5, .75])
value(o)
```


### QuantReg
Quantile Regression via an online MM algorithm.
```julia
o = QuantReg(x, y, .8)
coef(o)
```


### StatLearn
Statistical learning algorithms defined by model, algorithm, and penalty (regularization).
See [StatLearn Documentation](StatLearn.md).
```julia
o = StatLearn(o, LearningRate(.6), L2Regression(), SGD(), L2Penalty(), λ = .1)
coef(o)
predict(o, x)
loss(o, x, y)
```

### Variance
Univariate variance.
```julia
o = Variance(y)
var(o)
std(o)
mean(o)
```


### Variances
Variances of multiple series.
```julia
o = Variances(x)
var(o)
std(o)
mean(o)
```
