# Online algorithms implementation progress

## [x] Summary statistics

| Item                    |Associated Type(s)| Notes
|-------------------------|------------------|------------------
| ////////////////////////////////////|/////////////////////////////////////////////////////////////////////////////// | ///////////////
| [x] sample mean         |  `Summary`       |
| [x] sample variance     |  `Summary`       |
| [x] skewness and m3)    |  `Moments`       |
| [x] kurtosis (and m4)   |  `Moments`       | Pebay updates unstable?
|[x] covariance matrix| `CovarianceMatrix`|
|[x] maximum/minimum  |  `Summary`, `FiveNumberSummary` |
|[x] sample quantiles | `QuantileSGD`, `QuantileMM` |
|[x] 5-number summary | `FiveNumberSummary`  |
|[x] box plot  |`Gadfly.plot(obj::FiveNumberSummary)`

## Density estimation

* [ ] Gaussian mixture
* [ ] average shifted histograms (ASH)

## Univariate distributions

 *No `Distributions.suffstats` method.

* [x] Bernoulli
* [ ] beta*
* [x] binomial
* [ ] Cauchy*
* [ ] chi-square*
* [x] exponential
* [ ] F-distribution*
* [x] gamma
* [ ] inverse gamma*
* [ ] lognormal
* [x] normal
* [ ] t-distribution*
* [ ] Weibull*

## Multivariate distributions

* [x] multinomial
* [x] multivariate normal 
* [ ] multivariate normal with missing data
* [ ] multivariate t-distribution
* [ ] Dirichlet-multinomial
* [ ] negative multinomial

## Linear regression

* [ ] linear regression by Cholesky
* [ ] linear regression by sweep
* [ ] linear regression with missing data
* [ ] stepwise regression

## Generalized linear model (GLM)

* [ ] logistic regression
* [ ] Probit regression
* [ ] Poisson regression
* [ ] multinomial logistic regression
* [ ] Cox model

## Quantile regression

* [ ] linear quantile regression
* [ ] composite linear quantile regression

## Variance component model

* [ ] variance component model
* [ ] linear mixed model

## Penalized estimation

* [ ] lasso

## Multivariate statistics

* [ ] principal components analysis
* [ ] canonical correlation analysis
* [ ] factor analysis
