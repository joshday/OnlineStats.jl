# Available Statistics and Models

### BernoulliBootstrap
Double-or-nothing statistical bootstrap for estimating variance of an OnlineStat.
```julia
b = BernoulliBootstrap(Mean(), mean, 1000)  # create 1000 replicates
fit!(b, randn(10_000))  
```


### CompareTracePlot
Compare multiple OnlineStats by plotting each series on the same graph.  
```julia
using Plots
m = Mean()
v = Variance()

# arguments:  Vector of OnlineStats, function that returns a scalar
tr = CompareTracePlot([m, v], value)  
for i in 1:10
    fit!(tr, randn(100))
end
plot(tr)
```


### CovMatrix
Covariance Matrix.  
```julia
o = CovMatrix(randn(1000, 5), EqualWeight())
cov(o)
cor(o)
var(o)
std(o)
mean(o)
```


### Extrema
Maximum and minimum of univariate data (ignores Weight).
```julia
o = Extrema(rand(10_000))
extrema(o)
```


### Fitting Distributions
Estimate the parameters of a distribution.
```julia
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


### FitCategorical
FitCategorical gets special mention for its usefulness in keeping track of the number
levels and keeping them sorted by frequency.  Useful when the input variable is known
to have a finite number of levels.

```julia
y = rand(["a", "b", "c"], 1000)
o = FitCategorical(y)

y = rand(1:3, 1000);
fit!(o, y)
```


### HyperLogLog (see http://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf)
Approximate count of unique elements.  By nature of the HyperLogLog algorithm, the second
argument to `fit!(o, y)` is considered a singleton.  To update the object with a vector
of observations, follow the example below.
```julia
o = HyperLogLog(b)  # b ∈ 4:16
for yi in y
    fit!(o, yi)
end
value(o)
```


### KMeans
K-Means clustering of multivariate data
```julia
o = KMeans(y, 3)
value(o)
```


### LinReg
Linear regression with optional regularization.  Multiple penalties and tuning parameters
can be applied to the same object.  Using EqualWeight produces the same estimates as
offline linear regression.  
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
coef(o, L2Penalty(.1))  # Ridge
coef(o, L1Penalty(.1))  # LASSO
coef(o, ElasticNetPenalty(.1, .5))
coef(o, SCADPenalty(.1, 3.7))
```


### Mean
Univariate mean.
```julia
o = Mean(randn(1000))
mean(o)
```


### Means
Means of multiple series.
```julia
o = Means(randn(1000, 5))
mean(o)
```


### Moments
First four moments of univariate data.
```julia
o = Moments(randn(10_000))
mean(o)
var(o)
std(o)
skewness(o)
kurtosis(o)
```


### QuantileSGD
Approximate quantiles via stochastic gradient descent.
```julia
o = QuantileSGD(randn(10_000), tau = [.25, .5, .75])
value(o)
```


### QuantileMM
Approximate quantiles via an online MM algorithm.  Typically more accurate/stable
than `QuantileSGD`.
```julia
o = QuantileMM(randn(10_000), tau = [.25, .5, .75])
value(o)
```


### QuantReg
Approximate Quantile Regression via an online MM algorithm.
```julia
n, p = 100_000, 10
x = randn(n, p)
y = x * collect(1.:p) + randn(n)

o = QuantReg(x, y, .5)
coef(o)
```


### StatLearn
Statistical learning algorithms defined by model, algorithm, and penalty (regularization).
See [StatLearn Documentation](StatLearn.md).

```julia
n, p = 100_000, 10
x = randn(n, p)
y = x * collect(1.:p) + randn(n)

o = StatLearn(x, y, LearningRate(.6), L2Regression(), SGD(), L2Penalty(.1))
coef(o)
predict(o, x)
loss(o, x, y)
using Plots; coefplot(o)
```


### TracePlot
Construct a TracePlot with an OnlineStat.  Each call to `fit!(o::TracePlot, args...)`
will update the corresponding OnlineStat and add a data point/points to the plot.
```julia
using Plots
gadfly()  # or pyplot(), plotly()

o = QuantileMM()
tr = TracePlot(o, value)  # second arg is a function used to get values from the OnlineStat
for i in 1:10
    fit!(tr, randn(100))
end
plot(tr)
```


### Variance
Univariate variance.
```julia
o = Variance(randn(1000))
var(o)
std(o)
mean(o)

x = randn()
center(o, x)       # x - mean(o)
standardize(o, x)  # (x - mean(o)) / std(o)
```


### Variances
Variances of multiple series.
```julia
o = Variances(randn(1000, 5))
var(o)
std(o)
mean(o)

x = randn(5)
center(o, x)       # x - mean(o)
standardize(o, x)  # (x - mean(o)) ./ std(o)
```
