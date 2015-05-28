# Online algorithms implementation progress

Click links to example.

## Summary statistics

[Comparison of `QuantileSGD` and `QuantileMM`](../doc/quantilecompare.md)

| Item                 | Associated Type(s)
|----------------------|------------------
|  Sample Mean         |  `Mean`, `Means`, [`Summary`](../doc/Summary.md)       
|  Sample Variance     |  `Variance`, `Variances`, [`Summary`](../doc/Summary.md)   
|  Skewness (and m3)   |  [`Moments`](../doc/Moments.md)       
|  Kurtosis (and m4)   |  [`Moments`](../doc/Moments.md)        
|  Covariance Matrix   | [`CovarianceMatrix`](../doc/CovarianceMatrix.md)
|  Maximum/Minimum     |  [`Summary`](../doc/Summary.md)  , [`FiveNumberSummary`](../doc/FiveNumberSummary.md), `Extrema`
|  Sample Quantiles    | [`QuantileSGD`](../doc/QuantileSGD.md), [`QuantileMM`](../doc/QuantileMM.md) 
|  5-Number Summary    | [`FiveNumberSummary`](../doc/FiveNumberSummary.md)   
|  Box Plot            |[`Gadfly.plot(obj::FiveNumberSummary)`](../doc/FiveNumberSummary.md)  

## Density estimation

| Item                             | Associated Type(s)
|----------------------------------|------------------
| Gaussian mixture                 | `NormalMix`
| Average Shifted Histograms (ASH) | `AverageShiftedHistograms.update!` in [AverageShiftedHistograms](https://github.com/joshday/AverageShiftedHistograms.jl).  See also [Univariate example](https://github.com/joshday/AverageShiftedHistograms.jl/blob/master/doc/examples/update.md), [Bivariate example](https://github.com/joshday/AverageShiftedHistograms.jl/blob/master/doc/examples/update2.md)

## Univariate distributions

`OnlineFit____` objects can be created via `onlinefit(Dist, x)`

| Item                 | Associated Type(s)
|----------------------|------------------
| Bernoulli            | `OnlineFitBernoulli`
| Beta                 | `OnlineFitBeta`
| Binomial             | `OnlineFitBinomial`
| Cauchy               | 
| Chi-square           | 
| Exponential          | `OnlineFitExponential`
| F-distribution       | 
| Gamma                | `OnlineFitGamma`
| Inverse Gamma        | 
| Lognormal            | 
| Normal               | `OnlineFitNormal`
| T-distribution       | 
| Weibull              | 

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
| Sweep                | [`LinReg`](../doc/LinReg.md)
| Missing Data         |
| Stepwise regression  |

## Generalized linear model (GLM)

| Item                 | Associated Type(s)
|----------------------|------------------
| Logistic Regression  | `LogRegMM`, `LogRegSGD`, `LogRegSN`
| Probit Regression    | 
| Poisson Regression   |  
| Multinomial Logistic Regression |
| Cox Model            |

## Quantile regression


| Item                                 | Associated Type(s)
|--------------------------------------|------------------
| Linear Quantile Regression           | [`QuantRegSGD`](../doc/QuantRegSGD.md), [`QuantRegMM`](../doc/QuantRegMM.md)
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
