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
```julia
o = Extrema(y)
extrema(o)
```


### FitDistribution
```julia
o = FitDistribution(Bernoulli, y)
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
```julia
o = FitMvDistribution(Multinomial, x)
o = FitMvDistribution(MvNormal, x)
mean(o)
var(o)
std(o)
cov(o)
```


### KMeans
```julia
o = KMeans(x, k)
value(o)
```


### LinReg
```julia
o = LinReg(x, y)
coef(o)
coef(o, λ, L2Penalty())
coef(o, λ, L1Penalty())
coef(o, λ, ElasticNetPenalty())
coef(o, λ, SCADPenalty())
predict(o, x)
```


### Mean
```julia
o = Mean(y)
mean(o)
```


### Means
```julia
o = Means(x)
mean(o)
```


### Moments
```julia
o = Moments(y)
mean(o)
var(o)
std(o)
skewness(o)
kurtosis(o)
```


### QuantileSGD
```julia
o = QuantileSGD(y, tau = [.25, .5, .75])
value(o)
```


### QuantileMM
```julia
o = QuantileMM(y, tau = [.25, .5, .75])
value(o)
```


### QuantReg
```julia
o = QuantReg(x, y, .8)
coef(o)
```


### StatLearn
```julia
o = StatLearn(o, model = L2Regression(), algorithm = SGD(), penalty = NoPenalty())
coef(o)
predict(o, x)
loss(o, x, y)
```

### Variance
```julia
o = Variance(y)
var(o)
std(o)
mean(o)
```


### Variances
```julia
o = Variances(x)
var(o)
std(o)
mean(o)
```
