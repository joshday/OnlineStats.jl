# Models

In the descriptions, `x` is `Matrix{Float64}` and `y` is `Vector{Float64}`

## Summary Statistics

|                       |                                                                                       |
|:----------------------|:--------------------------------------------------------------------------------------|
| **Mean**              | Univariate mean, similar to `mean(y)`                                                 |
| **Means**             | Column means, similar to `mean(x, 1)`                                                 |
| **Variance**          | Univariate variance, similar to `var(y)`                                              |
| **Variances**         | Column variances, similar to `var(x, 1)`                                              |
| **Extrema**           | Maximum/minimum. similar to `extrema(y)`                                              |
| **Summary**           | Summary statistics, similar to `mean(y), var(y), extrema(y)`                          |
| **FiveNumberSummary** | similar to `quantile(y, [0.0, .25, .5, .75, 1.0])`                                    |
| **QuantileSGD**       | Quantiles by Stochastic subgradient descent. similar to `quantile(y, [.25, .5, .75])` |
| **QuantileMM**        | Quantiles by online MM.  similar to `quantile(y, [.25, .5, .75])`                     |
| **Diff**              | track the previous value and last difference                                          |
| **Diffs**             | `Diff` by column                                                                      |

## Exact Linear Models

- **LinReg**
- **SparseReg**
