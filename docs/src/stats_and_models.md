# Statistics and Models

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| **Univariate Statistics:**         |                            |
| Mean                               | [`Mean`](@ref)             |
| Variance                           | [`Variance`](@ref)         |
| Quantiles                          | [`Quantile`](@ref) and [`PQuantile`](@ref) |
| Maximum/Minimum                    | [`Extrema`](@ref)          |
| Skewness and kurtosis              | [`Moments`](@ref)          |
| Sum                                | [`Sum`](@ref)              |
| Count                              | [`Count`](@ref)            |
| **Time Series:**                   |                            |
| Difference                         | [`Diff`](@ref)             |
| Lag                                | [`Lag`](@ref)              |
| Autocorrelation/autocovariance     | [`AutoCov`](@ref)          |
| **Multivariate Analysis:**         |                            |
| Covariance/correlation matrix      | [`CovMatrix`](@ref)        |
| Principal components analysis      | [`CovMatrix`](@ref)        |
| K-means clustering (SGD)           | [`KMeans`](@ref)           |
| Multiple univariate statistics     | [`MV`](@ref) and [`Group`](@ref) |
| **Nonparametric Density Estimation:**|                          |
| Histograms                         | [`Hist`](@ref)             |
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
| **Other:**                         |                            |
| Statistical Bootstrap              | [`Bootstrap`](@ref)        |
| Approx. count of distinct elements | [`HyperLogLog`](@ref)      |
| Reservoir sampling                 | [`ReservoirSample`](@ref)  |
| Callbacks                          | [`CallFun`](@ref), [`mapblocks`](@ref) |
| Summary of partition               | [`Partition`](@ref), [`IndexedPartition`](@ref) |
