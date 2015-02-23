# Online algorithms implementation progress

## [x] Summary statistics

Notes: `Moments` updates are a little unstable.  Typo in Pebay?

| Item                 | Associated Type(s)
|----------------------|------------------
|  Sample Mean         |  `Summary`       
|  Sample Variance     |  `Summary`       
|  Skewness (and m3)   |  `Moments`       
|  Kurtosis (and m4)   |  `Moments`        
|  Covariance Matrix   | `CovarianceMatrix`
|  Maximum/Minimum     |  `Summary`, `FiveNumberSummary` 
|  Sample Quantiles    | `QuantileSGD`, `QuantileMM` 
|  5-Number Summary    | `FiveNumberSummary`  
|  Box Plot            |`Gadfly.plot(obj::FiveNumberSummary)`

## Density estimation

| Item                             | Associated Type(s)
|----------------------------------|------------------
| Gaussian mixture                 |
| Average Shifted Histograms (ASH) | `ASH.update!` in [ASH](https://github.com/joshday/ASH.jl) package

## Univariate distributions

 *No `suffstats` method to base type on.

| Item                 | Associated Type(s)
|----------------------|------------------
| Bernoulli            | `OnlineFitBernoulli`
| Beta                 | *
| Binomial             | `OnlineFitBinomial`
| Cauchy               | *
| Chi-square           | *
| Exponential          | `OnlineFitExponential`
| F-distribution       | *
| Gamma                | `OnlineFitGamma`
| Inverse Gamma        | *
| Lognormal            | *
| Normal               | `OnlineFitNormal`
| T-distribution       | *
| Weibull              | *

## Multivariate distributions

| Item                 | Associated Type(s)
|----------------------|------------------
| Multinomial          | `OnlineFitMultinomial`
| Multivariate Normal  | `OnlineFitMvNormal`
| Multivariate Normal with missing data | 
| Multivariate t-distribution           |
| Dirichlet-Multinomial                 |
| Negative Multinomial                  |

## Linear regression

| Item                 | Associated Type(s)
|----------------------|------------------
| Cholesky             | 
| Sweep                | `OnlineLinearModel`
| Missing Data         |
| Stepwise regression  |

## Generalized linear model (GLM)

| Item                 | Associated Type(s)
|----------------------|------------------
| Logistic Regression  | 
| Probit Regression    | 
| Poisson Regression   |  
| Multinomial Logistic Regression |
| Cox Model            |

## Quantile regression

| Item                                 | Associated Type(s)
|--------------------------------------|------------------
| Linear Quantile Regression           |
| Composite Linear Quantile Regresison |

## Variance component model

| Item                     | Associated Type(s)
|--------------------------|------------------
| Variance Component Model |
| Linear Mixed Model       |

## Penalized estimation

| Item        | Associated Type(s)
|-------------|------------------
| LASSO       |
| Ridge       |
| Elastic Net |

## Multivariate statistics

| Item             | Associated Type(s)
|------------------|------------------
| PCA              |
| CCA              |
| Factor Analysis  |
