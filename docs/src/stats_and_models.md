```@setup statsmodels
ENV["GKSwstype"] = "100"
ENV["GKS_ENCODING"]="utf8"
```

# Statistics and Models

## Univariate Statistics

| Statistic             | OnlineStat                                  |
|:----------------------|:--------------------------------------------|
| Mean                  | [`Mean`](@ref)                              |
| Variance              | [`Variance`](@ref)                          |
| Quantiles             | [`Quantile`](@ref) and [`P2Quantile`](@ref) |
| Maximum/Minimum       | [`Extrema`](@ref)                           |
| Skewness and kurtosis | [`Moments`](@ref)                           |
| Sum                   | [`Sum`](@ref)                               |

## Plotting (See [Data Visualization](@ref))

!!! info
    Many `OnlineStat`s have Plot recipes beyond what is listed here.

| Plot         | OnlineStat                                                                   |
|:-------------|:-----------------------------------------------------------------------------|
| Big Data Viz | [`Partition`](@ref), [`IndexedPartition`](@ref), [`KIndexedPartition`](@ref) |
| Mosaic Plot  | [`Mosaic`](@ref)                                                             |
| HeatMap      | [`HeatMap`](@ref)                                                            |

## Time Series

| Statistic                      | OnlineStat                         |
|:-------------------------------|:-----------------------------------|
| Difference                     | [`Diff`](@ref)                     |
| Lag                            | [`Lag`](@ref)                      |
| Autocorrelation/autocovariance | [`AutoCov`](@ref)                  |
| Tracked history                | [`Trace`](@ref), [`StatLag`](@ref) |

## Multivariate Analysis

| Statistic/Model                | OnlineStat                            |
|:-------------------------------|:--------------------------------------|
| Covariance/correlation matrix  | [`CovMatrix`](@ref)                   |
| Principal components analysis  | [`CovMatrix`](@ref), [`CCIPCA`](@ref) |
| K-means clustering             | [`KMeans`](@ref)                      |
| Multiple univariate statistics | [`Group`](@ref)                       |

## Nonparametric Density Estimation

| Statistic/Model                              | OnlineStat                                                   |
|:---------------------------------------------|:-------------------------------------------------------------|
| Histograms/continuous density                | [`Hist`](@ref), [`KHist`](@ref), and [`ExpandingHist`](@ref) |
| ASH density (semiparametric, similar to KDE) | [`Ash`](@ref)                                                |
| Approximate order statistics                 | [`OrderStats`](@ref)                                         |
| Count for each unique value                  | [`CountMap`](@ref)                                           |
| Approximate CDF                              | [`OrderStats`](@ref)                                         |

## Parametric Density Estimation

| Distribution | OnlineStat               |
|:-------------|:-------------------------|
| Beta         | [`FitBeta`](@ref)        |
| Cauchy       | [`FitCauchy`](@ref)      |
| Gamma        | [`FitGamma`](@ref)       |
| LogNormal    | [`FitLogNormal`](@ref)   |
| Normal       | [`FitNormal`](@ref)      |
| Multinomial  | [`FitMultinomial`](@ref) |
| MvNormal     | [`FitMvNormal`](@ref)    |

## Machine/Statistical Learning

| Model                           | OnlineStat                                |
|:--------------------------------|:------------------------------------------|
| Linear (also ridge) regression  | [`LinReg`](@ref), [`LinRegBuilder`](@ref) |
| Decision Trees                  | [`FastTree`](@ref)                        |
| Random Forest                   | [`FastForest`](@ref)                      |
| Naive Bayes Classifier          | [`NBClassifier`](@ref)                    |
| ML via Stochastic Approximation | [`StatLearn`](@ref)                       |

## Other

| Statistic/Model                    | OnlineStat                                                               |
|:-----------------------------------|:-------------------------------------------------------------------------|
| Handling Missing Data              | [`FilterTransform`](@ref), [`CountMissing`](@ref), [`SkipMissing`](@ref) |
| Statistical Bootstrap              | [`Bootstrap`](@ref)                                                      |
| Approx. count of distinct elements | [`HyperLogLog`](@ref)                                                    |
| Random sample                      | [`ReservoirSample`](@ref)                                                |
| Moving Window                      | [`MovingWindow`](@ref), [`MovingTimeWindow`](@ref)                       |

## Collection of Stats

| Statistic/Model               | OnlineStat                           |
|:------------------------------|:-------------------------------------|
| Univariate data stream        | [`Series`](@ref), [`FTSeries`](@ref) |
| Multivariate data streams     | [`Group`](@ref)                      |
| Group by categorical variable | [`GroupBy`](@ref)                    |


## Stochastic Approximation with [`StatLearn`](@ref) 

### Regression and Classification Losses

| Loss                                         | Function                           |
|:---------------------------------------------|:-----------------------------------|
| ``L_{2}`` Loss (squared error)               | [`OnlineStats.l2regloss`](@ref)    |
| ``L_{1}`` Loss (absolute error)              | [`OnlineStats.l1regloss`](@ref)    |
| Logistic Loss                                | [`OnlineStats.logisticloss`](@ref) |
| ``L_{1}`` Hinge Loss                         | [`OnlineStats.l1hingeloss`](@ref)  |
| Generalized distance weighted discrimination | [`OnlineStats.DWDLoss`](@ref)      |

### Penalty/regularization functions 

| Penalty                    | Function                         |
|:---------------------------|:---------------------------------|
| None                       | `zero`                           |
| LASSO (``L_{1}`` penalty)  | `abs`                            |
| Ridge  (``L_{2}`` penalty) | `abs2`                           |
| Elastic Net                | [`OnlineStats.ElasticNet`](@ref) |      

### Optimization Algorithms

| Algorithm                                                  | Constructor        |
|:-----------------------------------------------------------|:-------------------|
| Stochastic Gradient Descent                                | [`SGD`](@ref)      |
| RMSProp                                                    | [`RMSPROP`](@ref)  |
| AdaGrad                                                    | [`ADAGRAD`](@ref)  |
| AdaDelta                                                   | [`ADADELTA`](@ref) |
| ADAM                                                       | [`ADAM`](@ref)     |
| ADAMax                                                     | [`ADAMAX`](@ref)   |
| MSPI (Majorized Stochastic Proximal Iteration)             | [`MSPI`](@ref)     |
| Online Majorization-Minimization (MM) - averaged surrogate | [`OMAS`](@ref)     |
| Online MM - Averaged Parameter                             | [`OMAP`](@ref)     |
