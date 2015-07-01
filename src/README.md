# Online Algorithms Implementation Progress

## Summary Statistics

- [x] Mean: `Mean`, `Means`
- [x] Variance: `Variance`, `Variances`
- [x] Covariance Matrix: `CovarianceMatrix`
- [x] Skewness, Kurtosis: `Moments`
- [x] Maximum/Minimum: `Extrema`
- [x] Quantiles: `QuantileMM`, `QuantileSGD`
- [x] Five Number Summary: `FiveNumberSummary`

## Multivariate Analysis

- [x] PCA: `AnalyticalPCA`, `OnlinePCA`
- [ ] CCA:
- [ ] Factor Analysis:

## Density Estimation
See also: [AverageShiftedHistograms](https://github.com/joshday/AverageShiftedHistograms.jl)
### Univariate Distributions
- [x] Univariate Normal Mixture: `NormalMix`
- [x] Bernoulli: `FitBernoulli`
- [x] Beta: `FitBeta`
- [x] Binomial: `FitBinomial`
- [ ] Cauchy:
- [ ] Chi-square:
- [x] Exponential: `FitExponential`
- [ ] F-distribution:
- [x] Gamma: `FitGamma`
- [ ] Lognormal:
- [ ] Poisson
- [x] Normal: `FitNormal`
- [ ] T-distribution:
- [ ] Weibull:
- [ ] Zero-inflated Mixtures

### Multivariate Distributions
- [ ] Dirichlet-Multinomial
- [x] Multinomial: `FitMultinomial`
- [x] Multivariate Normal: `FitMvNormal`
- [ ] Multivariate T-distribution
- [ ] Negative Multinomial

## Linear Models
- [x] OLS: `LinReg`
- [ ] Stepwise Regression:

### Penalized Regression
- [ ] LASSO:
- [ ] Ridge:
- [ ] Elastic Net:

### Quantile Regression
- [x] Linear Quantile Regression: `QuantRegMM`, `QuantRegSGD`
- [ ] Composite Linear Quantile Regression:

### Variance Component Model
- [ ] Variance Component Model
- [ ] Linear Mixed Model

## Generalized Linear Models (GLM)
- [ ] Cox Model
- [x] Logistic Regression: `LogRegMM`, `LogRegSGD`, `LogRegSGD2`
- [ ] Multinomial Logistic Regression
- [ ] Poisson Regression
- [ ] Probit Regression
