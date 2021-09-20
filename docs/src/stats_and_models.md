```@setup statsmodels
ENV["GKSwstype"] = "100"
ENV["GKS_ENCODING"]="utf8"
```

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
| Stochastic Approximation ML        | [`StatLearn`](@ref)        |

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

## Notes on `StatLearn`

The `StatLearn` (short for statistical learning) OnlineStat uses stochastic approximation methods to estimate models that take the form:

``\frac{1}{n} \sum_i f(y_i, x_i'\beta) + \sum_j \lambda_j g(\beta_j),``

where 

- ``f`` is a **loss function** of a response variable and linear preditor.
- ``\lambda_j``'s are nonnegative regularization parameters.
- ``g`` is a **penalty function**.

For example, [LASSO Regression](https://en.wikipedia.org/wiki/Lasso_(statistics)) fits this form with:

- ``f(y_i, x_i'\beta) = \frac{1}{2}(y_i - x_i'\beta) ^ 2``
- ``g(\beta_j) = \|\beta_j\|``

OnlineStats implements interchangeable loss and penalty functions to use for both regression and classification problems.  See the [`StatLearn`](@ref) docstring for details.

### Stochastic Approximation

An important note is that [`StatLearn`](@ref) is unable to estimate coefficients exactly (For precision in regression problems, see [`LinReg`](@ref)).  The upside is that it makes estimating certain models *possible* in an online fashion.  

For example, it is **not possible** to get the same coefficients for logistic regression from an O(1) *online* algorithm as you would get from its *offline* counterpart.  This is because the logistic regression likelihood's [sufficient statistics](https://en.wikipedia.org/wiki/Sufficient_statistic) scale with the number of observations.

**All this to say: `StatLearn` lets you do things that would otherwise not be possible at the cost of returning noisy estimates.**

### Algorithms

Besides the loss and penalty functions, you can also plug in a variety of fitting algorithms to `StatLearn`.  Some of these methods are based on the stochastic gradient (gradient of loss evaluated on a single observation).  Other methods are based on the [majorization-minimization (MM)](https://en.wikipedia.org/wiki/MM_algorithm) principle, which offers some guarantees on numerical stability (sometimes at the cost of slower learning).  It is a good idea to test out different algorithms on a sample of your dataset.  Plotting the coefficients over time can give you an idea of the stability of the estimates.  Keep in mind the early observations will cause bigger jumps in the cofficients than later observations (based on the learning rate; see [Weights](@ref).  Here's an example:

```@example statsmodels
using OnlineStats, Plots

# fake data
x = rand(Bool, 1000, 10)
y = x * (1:10) + 10randn(1000)

rate = LearningRate(.8)

o = StatLearn(SGD(), OnlineStats.l2regloss; rate)
o2 = StatLearn(MSPI(), OnlineStats.l2regloss; rate)

coefs = zeros(1000, 10)
coefs2 = zeros(1000, 10)

for (i, xy) in enumerate(zip(eachrow(x), y))
    coefs[i, :] = coef(fit!(o, xy))
    coefs2[i, :] = coef(fit!(o2, xy))
end

plot(
    plot(coefs, xlab="Nobs", title="SGD Coefficients", lab=nothing),
    plot(coefs2, xlab="Nobs", title="MSPI Coefficients", lab=nothing),
    link=:y
)
```

To add further complexity, learning rates (supplied by the `rate` keyword argument) do not affect each algorithm's learning uniformly.  You may need to test different combinations of algorithm/learning rate to find an "optimal" pairing.

At the moment, the only place to read about the stochastic MM algorithms in detail is [Josh Day's dissertation](https://en.wikipedia.org/wiki/MM_algorithm).  Josh is working on an easier-to-digest introduction to these methods and is also happy to discuss them through GitHub issue/email.
