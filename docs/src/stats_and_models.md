# Statistics and Models

## Univariate Statistics

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Mean                               | [`Mean`](@ref)             |
| Variance                           | [`Variance`](@ref)         |
| Quantiles                          | [`Quantile`](@ref) and [`P2Quantile`](@ref) |
| Maximum/Minimum                    | [`Extrema`](@ref)          |
| Skewness and kurtosis              | [`Moments`](@ref)          |
| Sum                                | [`Sum`](@ref)              |

## Time Series

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Difference                         | [`Diff`](@ref)             |
| Lag                                | [`Lag`](@ref)              |
| Autocorrelation/autocovariance     | [`AutoCov`](@ref)          |
| Tracked history                    | [`StatLag`](@ref)          |

## Multivariate Analysis

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Covariance/correlation matrix      | [`CovMatrix`](@ref)        |
| Principal components analysis      | [`CovMatrix`](@ref), [`CCIPCA`](@ref)        |
| K-means clustering (SGD)           | [`KMeans`](@ref)           |
| Multiple univariate statistics     | [`Group`](@ref) |

## Nonparametric Density Estimation

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Histograms/continuous density      | [`Hist`](@ref) and [`KHist`](@ref) |
| Approximate order statistics       | [`OrderStats`](@ref)       |
| Count for each unique value        | [`CountMap`](@ref)         |
| Approximate CDF                    | [`OrderStats`](@ref)

## Parametric Density Estimation

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Beta                               | [`FitBeta`](@ref)          |
| Cauchy                             | [`FitCauchy`](@ref)        |
| Gamma                              | [`FitGamma`](@ref)         |
| LogNormal                          | [`FitLogNormal`](@ref)     |
| Normal                             | [`FitNormal`](@ref)        |
| Multinomial                        | [`FitMultinomial`](@ref)   |
| MvNormal                           | [`FitMvNormal`](@ref)      |

## Statistical Learning

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| GLMs with regularization           | [`StatLearn`](@ref)        |
| Logistic regression                | [`StatLearn`](@ref)        |
| Linear SVMs                        | [`StatLearn`](@ref)        |
| Quantile regression                | [`StatLearn`](@ref)        |
| Absolute loss regression           | [`StatLearn`](@ref)        |
| Distance-weighted discrimination   | [`StatLearn`](@ref)        |
| Huber-loss regression              | [`StatLearn`](@ref)        |
| Linear (also ridge) regression     | [`LinReg`](@ref), [`LinRegBuilder`](@ref) |
| Decision Trees                     | [`FastTree`](@ref)         |
| Random Forest                      | [`FastForest`](@ref)       |
| Naive Bayes Classifier             | [`NBClassifier`](@ref)     |

## Other

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Handling Missing DAta              | [`FTSeries`](@ref), [`CountMissing`](@ref)
| Statistical Bootstrap              | [`Bootstrap`](@ref)        |
| Approx. count of distinct elements | [`HyperLogLog`](@ref)      |
| Reservoir sampling                 | [`ReservoirSample`](@ref)  |
| Big Data Viz                       | [`Partition`](@ref), [`IndexedPartition`](@ref) |

## Collection of Stats

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Apply stats to same data stream    | [`Series`](@ref), [`FTSeries`](@ref) |
| Apply stats to different data streams  | [`Group`](@ref)
| Calculate stat by group            | [`GroupBy`](@ref)          |
