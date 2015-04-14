# Online algorithms implementation progress

Click links to example.

## Summary statistics

[Comparison of `QuantileSGD` and `QuantileMM`](../doc/examples/quantilecompare.md)

| Item                 | Associated Type(s)
|----------------------|------------------
|  Sample Mean         |  [`Summary`](../doc/examples/Summary.md)       
|  Sample Variance     |  [`Summary`](../doc/examples/Summary.md)   
| Extrema              | `Extrema`     
|  Skewness (and m3)   |  [`Moments`](../doc/examples/Moments.md)       
|  Kurtosis (and m4)   |  [`Moments`](../doc/examples/Moments.md)        
|  Covariance Matrix   | [`CovarianceMatrix`](../doc/examples/CovarianceMatrix.md)
|  Maximum/Minimum     |  [`Summary`](../doc/examples/Summary.md)  , [`FiveNumberSummary`](../doc/examples/FiveNumberSummary.md) 
|  Sample Quantiles    | [`QuantileSGD`](../doc/examples/QuantileSGD.md), [`QuantileMM`](../doc/examples/QuantileMM.md) 
|  5-Number Summary    | [`FiveNumberSummary`](../doc/examples/FiveNumberSummary.md)   
|  Box Plot            |[`Gadfly.plot(obj::FiveNumberSummary)`](../doc/examples/FiveNumberSummary.md)  

## Density estimation

| Item                             | Associated Type(s)
|----------------------------------|------------------
| Gaussian mixture                 | [`NormalMix`](../doc/examples/NormalMix.md)
| Average Shifted Histograms (ASH) | `AverageShiftedHistograms.update!` in [AverageShiftedHistograms](https://github.com/joshday/AverageShiftedHistograms.jl).  See also [Univariate example](https://github.com/joshday/AverageShiftedHistograms.jl/blob/master/doc/examples/update.md), [Bivariate example](https://github.com/joshday/AverageShiftedHistograms.jl/blob/master/doc/examples/update2.md)

## Univariate distributions

| Item                 | Associated Type(s)
|----------------------|------------------
| Bernoulli            | [`OnlineFitBernoulli`](../doc/examples/OnlineFitBernoulli.md)
| Beta                 | [`OnlineFitBeta`](../doc/examples/OnlineFitBeta.md)
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
| Sweep                | [`OnlineLinearModel`](../doc/examples/OnlineLinearModel.md)
| Missing Data         |
| Stepwise regression  |

## Generalized linear model (GLM)

| Item                 | Associated Type(s)
|----------------------|------------------
| Logistic Regression  | [`LogRegMM`](../doc/examples/LogRegMM.md), `LogRegSGD`, `LogRegSN`
| Probit Regression    | 
| Poisson Regression   |  
| Multinomial Logistic Regression |
| Cox Model            |

## Quantile regression

[Comparison of `QuantRegSGD` vs. `QuantRegMM`](../doc/examples/quantregcompare.md)

| Item                                 | Associated Type(s)
|--------------------------------------|------------------
| Linear Quantile Regression           | [`QuantRegSGD`](../doc/examples/QuantRegSGD.md), [`QuantRegMM`](../doc/examples/QuantRegSGD.md)
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
