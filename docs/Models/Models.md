# Models

In the descriptions, `x` is `Matrix{Float64}` and `y` is `Vector{Float64}`

## Summary Statistics

|                       |                                                                                                  |
|:----------------------|:-------------------------------------------------------------------------------------------------|
| **CovarianceMatrix**  | similar to `cov(x)`                                                                              |
| **Diff**              | track the previous value and last difference                                                     |
| **Diffs**             | `Diff` by column                                                                                 |
| **Extrema**           | Maximum/minimum. similar to `extrema(y)`                                                         |
| **FiveNumberSummary** | Exact max/min and approximate quantiles, similar to `quantile(y, [0.0, .25, .5, .75, 1.0])`      |
| **Mean**              | Univariate mean, similar to `mean(y)`                                                            |
| **Means**             | Column means, similar to `mean(x, 1)`                                                            |
| **Moments**           | First four moments: tracks mean, variance, skewness, and kurtosis                                |
| **QuantileSGD**       | Approximate uantiles by Stochastic subgradient descent. similar to `quantile(y, [.25, .5, .75])` |
| **QuantileMM**        | Approximate quantiles by online MM.  similar to `quantile(y, [.25, .5, .75])`                    |
| **Summary**           | Summary statistics, similar to `mean(y), var(y), extrema(y)`                                     |
| **Variance**          | Univariate variance, similar to `var(y)`                                                         |
| **Variances**         | Column variances, similar to `var(x, 1)`                                                         |


## Exact Solution Models

|                                 |                                                                                                                                            |
|:--------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------|
| **LinReg**                      | Analytical linear regression                                                                                                               |
| *Principal Components Analysis* | *Not a type*.  `pca(o::CovarianceMatrix; maxoutdim = k)`.  Return top `k` principal components                                             |
| **SparseReg**                   | Analytical sparse linear regression.  Ordinary least squares, ridge, lasso, and elastic net estimates can all be retrieved from this type. |
| **StepwiseReg**                 | (Experimental).  Online stepwise regression.                                                                                               |

## Approximate Solution Models

|                               |                                                                                            |
|:------------------------------|:-------------------------------------------------------------------------------------------|
| **QuantRegMM**                | Quantile regression via an online MM algorithm                                             |
| **[SGModel](SGModel.md)**     | Fit a variety of stochastic (sub)gradient models with regularization.                      |
| **[SGModelTune](SGModel.md)** | Fit an `SGModel` while automatically adjusting the tuning parameter for the regularization |



## Parametric Density Estimation

To fit a parametric density (provided by the Distributions package), use

```julia
o = distributionfit(Dist, data)
```

| OnlineStat type    | Associated Distributions type                            |
|:-------------------|:---------------------------------------------------------|
| **FitBernoulli**   | Bernoulli                                                |
| **FitBeta**        | Beta                                                     |
| **FitBinomial**    | Binomial                                                 |
| **FitCauchy**      | Cauchy                                                   |
| **FitExponential** | Exponential                                              |
| **FitGamma**       | Gamma                                                    |
| **FitLogNormal**   | LogNormal                                                |
| **FitMultinomial** | Multinomial                                              |
| **FitMvNormal**    | MvNormal                                                 |
| **FitNormal**      | Normal                                                   |
| **FitPoisson**     | Poisson                                                  |
| **NormalMix**      | MixtureModel{Normal} (Univariate gaussian mixture model) |
