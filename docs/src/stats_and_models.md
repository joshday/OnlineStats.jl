# Statistics and Models

## Univariate Statistics

| Statistic                          | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Mean                               | [`Mean`](@ref)             |
| Variance                           | [`Variance`](@ref)         |
| Quantiles                          | [`Quantile`](@ref) and [`P2Quantile`](@ref) |
| Maximum/Minimum                    | [`Extrema`](@ref)          |
| Skewness and kurtosis              | [`Moments`](@ref)          |
| Sum                                | [`Sum`](@ref)              |

## Data Visualization (See [Data Viz](@ref))

- Note that many `OnlineStat`s also have Plot recipes.

| Plot                               | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Big Data Viz                       | [`Partition`](@ref), [`IndexedPartition`](@ref), [`KIndexedPartition`](@ref) |
| Mosaic Plot                        | [`Mosaic`](@ref)           |
| HeatMap                            | [`HeatMap`](@ref)           |

## Time Series

| Statistic                          | OnlineStat                 |
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
| K-means clustering                 | [`KMeans`](@ref)           |
| Multiple univariate statistics     | [`Group`](@ref) |

## Nonparametric Density Estimation

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Histograms/continuous density      | [`Hist`](@ref), [`KHist`](@ref), and [`ExpandingHist`](@ref) |
| ASH KDE                            | [`Ash`](@ref)              |
| Approximate order statistics       | [`OrderStats`](@ref)       |
| Count for each unique value        | [`CountMap`](@ref)         |
| Approximate CDF                    | [`OrderStats`](@ref)

## Parametric Density Estimation

| Distribution                       | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Beta                               | [`FitBeta`](@ref)          |
| Cauchy                             | [`FitCauchy`](@ref)        |
| Gamma                              | [`FitGamma`](@ref)         |
| LogNormal                          | [`FitLogNormal`](@ref)     |
| Normal                             | [`FitNormal`](@ref)        |
| Multinomial                        | [`FitMultinomial`](@ref)   |
| MvNormal                           | [`FitMvNormal`](@ref)      |

## Statistical Learning

| Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Linear (also ridge) regression     | [`LinReg`](@ref), [`LinRegBuilder`](@ref) |
| Decision Trees                     | [`FastTree`](@ref)         |
| Random Forest                      | [`FastForest`](@ref)       |
| Naive Bayes Classifier             | [`NBClassifier`](@ref)     |

## Other

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Handling Missing Data              | [`FTSeries`](@ref), [`CountMissing`](@ref)
| Statistical Bootstrap              | [`Bootstrap`](@ref)        |
| Approx. count of distinct elements | [`HyperLogLog`](@ref)      |
| Random sample                      | [`ReservoirSample`](@ref)  |
| Moving Window                      | [`MovingWindow`](@ref), [`MovingTimeWindow`](@ref) |

## Collection of Stats

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Univariate data stream             | [`Series`](@ref), [`FTSeries`](@ref) |
| Multivariate data streams          | [`Group`](@ref)            |
| Group by categorical variable      | [`GroupBy`](@ref)          |

## Machine Learning

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| Linear SGD                         | [`StatLearn`](@ref)        |

### Regression and Classification Losses

| Loss                               | Function                   |
|:-----------------------------------|:---------------------------|
| ``L_{2}`` Loss (squared error)     | [`l2regloss`](@ref)        |
| ``L_{1}`` Loss (absolute error)    | [`l1regloss`](@ref)        |
| Logistic Loss                      | [`logisticloss`](@ref)     |
| ``L_{1}`` Hinge Loss               | [`l1hingeloss`](@ref)      |
| Generalized distance weighted discrimination | [`DWDLoss`](@ref)|

### Optimization Algorithms

| Algorithm                               | Constructor           |
|:----------------------------------------|:----------------------|
| Stochastic Gradient Descent             | [`SGD`](@ref)         |
| Majorization Minimization (averaged surrogate) | [`OMAS`](@ref) |
| Majorization Minimization (averaged parameter) | [`OMAP`](@ref) |

