# Online Algorithms Implementation Progress

# WARNING: This is typically outdated

## Summary Statistics
- [x] Mean: `Mean`, `Means`
- [x] Variance: `Variance`, `Variances`
- [x] Covariance Matrix: `CovarianceMatrix`
- [x] Skewness, Kurtosis: `Moments`
- [x] Maximum/Minimum: `Extrema`
- [x] Quantiles: `QuantileMM`, `QuantileSGD`
- [x] Five Number Summary: `FiveNumberSummary`

## Multivariate Analysis
- [x] PCA: `pca(o::CovarianceMatrix)`
- [ ] CCA:
- [ ] Factor Analysis:

## Density Estimation
See also: [AverageShiftedHistograms](https://github.com/joshday/AverageShiftedHistograms.jl)

### Univariate Distributions
- [x] Bernoulli: `FitBernoulli`
- [x] Beta: `FitBeta`
- [x] Binomial: `FitBinomial`
- [x] Cauchy: `FitCauchy`
- [ ] Chi-square:
- [x] Exponential: `FitExponential`
- [ ] F-distribution:
- [x] Gamma: `FitGamma`
- [x] Lognormal: `FitLogNormal`
- [x] Poisson: `FitPoisson`
- [x] Normal: `FitNormal`
- [x] Normal Mixture: `NormalMix`
- [ ] T-distribution:
- [ ] Weibull:
- [ ] Zero-inflated Mixtures

### Multivariate Distributions
- [ ] Dirichlet-Multinomial
- [x] Multinomial: `FitMultinomial`
- [x] Multivariate Normal: `FitMvNormal`
- [ ] Multivariate Normal Mixture:
- [ ] Multivariate T-distribution
- [ ] Negative Multinomial

## Linear Models
- [x] OLS: `LinReg`, `SparseReg`, `StochasticModel`
- [x] L1 Loss Regression: `StochasticModel`
- [x] Huber Loss Regression: `StochasticModel`
- [x] Stepwise Regression: `StepwiseReg` (experimental)

### Penalized Regression
- [x] LASSO: `SparseReg`, `StochasticModel`
- [x] Ridge: `SparseReg`, `StochasticModel`
- [x] Elastic Net: `SparseReg`

### Quantile Regression
- [x] Linear Quantile Regression: `QuantRegMM`, `StochasticModel`
- [ ] Composite Linear Quantile Regression:

### Variance Component Model
- [ ] Variance Component Model
- [ ] Linear Mixed Model

## Generalized Linear Models (GLM)
- [ ] Cox Model
- [x] Logistic Regression: `LogRegMM`, `StochasticModel`
- [ ] Multinomial Logistic Regression
- [x] Poisson Regression: `StochasticModel`
- [ ] Probit Regression

## Other
- [x] Support Vector Machine: `StochasticModel`
