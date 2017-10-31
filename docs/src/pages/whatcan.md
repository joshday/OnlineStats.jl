# What Can OnlineStats Do?

| Statistic/Model                    | OnlineStat                 |
|:-----------------------------------|:---------------------------|
| **Univariate Statistics:**         |                            |
| Mean                               | [`Mean`](@ref)             |
| Variance                           | [`Variance`](@ref)         |
| Quantiles                 | [`QuantileMM`](@ref), [`QuantileMSPI`](@ref), [`QuantileSGD`](@ref)|
| Maximum/Minimum                    | [`Extrema`](@ref)          |
| Skewness and kurtosis              | [`Moments`](@ref)          |
| Sum                                | [`Sum`](@ref)              |
| Difference                         | [`Diff`](@ref)             |
| Histogram                          | [`OHistogram`](@ref)       |
| Average order statistics           | [`OrderStats`](@ref)  |
| **Multivariate Analysis:**         |                            |
| Covariance matrix                  | [`CovMatrix`](@ref)        |
| K-means clustering                 | [`KMeans`](@ref)           |
| Multiple univariate statistics     | [`MV{<:OnlineStat}`](@ref) |
| **Density Estimation:**            |                            |
| Beta                               | [`FitBeta`](@ref)          |
| Categorical                        | [`FitCategorical`](@ref)   |
| Cauchy                             | [`FitCauchy`](@ref)        |
| Gamma                              | [`FitGamma`](@ref)         |
| LogNormal                          | [`FitLogNormal`](@ref)     |
| Normal                             | [`FitNormal`](@ref)        |
| Multinomial                        | [`FitMultinomial`](@ref)   |
| MvNormal                           | [`FitMvNormal`](@ref)      |
| **Statistical Learning:**          |                            |
| GLMs with regularization           | [`StatLearn`](@ref)        |
| Linear (also ridge) regression     | [`LinReg`](@ref), [`LinRegBuilder`](@ref) |
| **Other:**                         |                            |
| Bootstrapping                      | [`Bootstrap`](@ref)        |
| Approx. count of distinct elements | [`HyperLogLog`](@ref)      |
| Reservoir sampling                 | [`ReservoirSample`](@ref)  |
