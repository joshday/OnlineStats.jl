# Online algorithms implementation progress


## Summary statistics

Notes: `Moments` updates are a little unstable.  Typo in Pebay?

| Item                 | Associated Type(s)
|----------------------|------------------
|  Sample Mean         |  [`Summary`](../doc/examples/summary.md)       
|  Sample Variance     |  [`Summary`](../doc/examples/summary.md)        
|  Skewness (and m3)   |  [`Moments`](../doc/examples/moments.md)       
|  Kurtosis (and m4)   |  [`Moments`](../doc/examples/moments.md)        
|  Covariance Matrix   | [`CovarianceMatrix`](../doc/examples/CovarianceMatrix.md)
|  Maximum/Minimum     |  [`Summary`](../doc/examples/summary.md)  , [`FiveNumberSummary`](../doc/examples/FiveNumberSummary.md) 
|  Sample Quantiles    | [`QuantileSGD`](../doc/examples/quantilesgd.md), [`QuantileMM`](../doc/examples/quantilemm.md) 
|  5-Number Summary    | [`FiveNumberSummary`](../doc/examples/FiveNumberSummary.md)   
|  Box Plot            |[`Gadfly.plot(obj::FiveNumberSummary)`](../doc/examples/FiveNumberSummary.md)  

## Density estimation

| Item                             | Associated Type(s)
|----------------------------------|------------------
| Gaussian mixture                 |
| Average Shifted Histograms (ASH) | `AverageShiftedHistograms.update!` in [AverageShiftedHistograms](https://github.com/joshday/AverageShiftedHistograms.jl) package

## Univariate distributions

 *No `suffstats` method to base type on.

| Item                 | Associated Type(s)
|----------------------|------------------
| Bernoulli            | `OnlineFitBernoulli`
| Beta                 | [`OnlineFitBeta`](../doc/examples/OnlineFitBeta.md)
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
| Sweep                | [`OnlineLinearModel`](../doc/examples/OnlineLinearModel.md)
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
