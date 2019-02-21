# Statistics and Models

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| **Univariate Statistics:**         |                            |
| Mean                               | [`Mean`](@ref)             |
| Variance                           | [`Variance`](@ref)         |
| Quantiles                          | [`Quantile`](@ref) and [`P2Quantile`](@ref) |
| Maximum/Minimum                    | [`Extrema`](@ref)          |
| Skewness and kurtosis              | [`Moments`](@ref)          |
| Sum                                | [`Sum`](@ref)              |
| **Time Series:**                   |                            |
| Difference                         | [`Diff`](@ref)             |
| Lag                                | [`Lag`](@ref)              |
| Autocorrelation/autocovariance     | [`AutoCov`](@ref)          |
| Tracked history                    | [`StatHistory`](@ref)      |
| **Multivariate Analysis:**         |                            |
| Covariance/correlation matrix      | [`CovMatrix`](@ref)        |
| Principal components analysis      | [`CovMatrix`](@ref)        |
| K-means clustering (SGD)           | [`KMeans`](@ref)           |
| Multiple univariate statistics     | [`Group`](@ref) |
| **Nonparametric Density Estimation:**|                          |
| Histograms/continuous density      | [`Hist`](@ref) and [`KHist`](@ref) |
| Approximate order statistics       | [`OrderStats`](@ref)       |
| Count for each unique value        | [`CountMap`](@ref)         |
| **Parametric Density Estimation:** |                            |
| Beta                               | [`FitBeta`](@ref)          |
| Cauchy                             | [`FitCauchy`](@ref)        |
| Gamma                              | [`FitGamma`](@ref)         |
| LogNormal                          | [`FitLogNormal`](@ref)     |
| Normal                             | [`FitNormal`](@ref)        |
| Multinomial                        | [`FitMultinomial`](@ref)   |
| MvNormal                           | [`FitMvNormal`](@ref)      |
| **Statistical Learning:**          |                            |
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
| **Other:**                         |                            |
| Statistical Bootstrap              | [`Bootstrap`](@ref)        |
| Approx. count of distinct elements | [`HyperLogLog`](@ref)      |
| Reservoir sampling                 | [`ReservoirSample`](@ref)  |
| Callbacks                          | [`CallFun`](@ref)          |
| Big Data Viz                       | [`Partition`](@ref), [`IndexedPartition`](@ref) |
| **Collections of Stats:**          |                            |
| Applied to same data stream        | [`Series`](@ref), [`FTSeries`](@ref) |
| Applied to different data streams  | [`Group`](@ref)
| Calculate stat by group            | [`GroupBy`](@ref)          |
