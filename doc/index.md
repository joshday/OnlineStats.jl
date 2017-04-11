# OnlineStats.jl

**OnlineStats** is a Julia package which provides online algorithms for statistical models.

Online algorithms are well suited for streaming data or when data is too large to hold in memory.

Observations are processed one at a time and all **algorithms use O(1) memory**.

**For OnlineStats v0.6 docs, click [here](https://github.com/joshday/OnlineStats.jl/tree/8686c286b5e775d2653b4226aac739a853abac4e/doc)**

---

## Overview
### Every OnlineStat is a Type
```julia
using OnlineStats
m, v = Mean(), Variance()
```

### OnlineStats are grouped by Series
```julia
s = Series(m, v)
```

### Updating a Series updates the OnlineStats
```julia
y = randn(100)

for yi in y
    fit!(s, yi)
end

# or more simply:
fit!(s, y)
```

###
```julia
nobs(s)   # Number of observations
stats(s)  # returns tuple of OnlineStats: (m, v)
value(s)  # returns tuple of values: (value(m), value(v))
```


---

## What Can OnlineStats Do?
While many estimates can be calculated analytically with an online algorithm, several
type rely on stochastic approximation.

| statistic/model                        | OnlineStat                    |
|:---------------------------------------|:------------------------------|
| mean                                   | `Mean`, `Variance`, `Moments` |
| variance                               | `Variance`, `Moments`         |
| quantiles                              | `QuantileSGD`, `QuantileMM`   |
| max and min                            | `Extrema`                     |
| skewness and kurtosis                  | `Moments`                     |
| sum                                    | `Sum`                         |
| difference                             | `Diff`                        |
| covariance matrix                      | `CovMatrix`                   |
| gaussian mixture                       | `NormalMix`                   |
| k-means clustering                     | `KMeans`                      |
| approximate count of distinct elements | `HyperLogLog`                 |

## Parametric Distributions
| distribution | OnlineStat       |
|:-------------|:-----------------|
| Beta         | `FitBeta`        |
| Categorical  | `FitCategorical` |
| Cauchy       | `FitCauchy`      |
| Gamma        | `FitGamma`       |
| LogNormal    | `FitLogNormal`   |
| Normal       | `FitNormal`      |
| Multinomial  | `FitMultinomial` |
| MvNormal     | `FitMvNormal`    |

## Other
- Statistical bootstrap of an OnlineStat: `Bootstrap`
