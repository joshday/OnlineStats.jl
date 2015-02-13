# OnlineStats

## Exported
---

#### CovarianceMatrix
Usage: `CovarianceMatrix(x::Matrix)`

| Field       |  Description                 |
|:------------|:-----------------------------|
| `A::Matrix` | $ X^T X / n $                |
| `B::Matrix` | $ X^T 1_n $                  |
| `n::Int64`  | number of observations used  |
| `p::Int64`  | number of variables          |
| `nb::Int64` | number of batches used       |


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/covmatrix.jl:25](https://github.com/joshday/OnlineStats.jl/tree/40ac77ff87902410a18f9abe4dd009ad4da42d3b/src/summary/covmatrix.jl#L25)

---

#### Moments
Usage: `Moments(y::Vector)`

| Field         |  Description                 |
|:--------------|:-----------------------------|
| `m1::Float64` | $ \mu_1 $                    |
| `m2::Float64` | $ \mu_2 $                    |
| `m3::Float64` | $ \mu_3 $                    |
| `m4::Float64` | $ \mu_4 $                    |
| `n::Int64`    | number of observations used  |
| `nb::Int64`   | number of batches used       |


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/moments.jl:28](https://github.com/joshday/OnlineStats.jl/tree/40ac77ff87902410a18f9abe4dd009ad4da42d3b/src/summary/moments.jl#L28)

---

#### QuantileMM
Usage: `QuantileMM(y::Vector)`

| Field         |  Description                 |
|:--------------|:-----------------------------|
| `est::Vector` | quantile results             |
| `τs::Vector ` | quantiles estimated          |
| `r::Float64 ` | learning rate                |
| `s::Float64 ` | sufficient statistic 1       |
| `t::Float64 ` | sufficient statistic 2       |
| `o::Float64 ` | sufficient statistic 3       |
| `n::Int64   ` | number of observations used  |
| `nb::Vector ` | number of batches used       |


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:60](https://github.com/joshday/OnlineStats.jl/tree/40ac77ff87902410a18f9abe4dd009ad4da42d3b/src/summary/quantile.jl#L60)

---

#### QuantileSGD
Usage: `QuantileSGD(y::Vector)`

| Field         |  Description                 |
|:--------------|:-----------------------------|
| `est::Vector` |  quantile results            |
| `τs::Vector ` |  quantiles estimated         |
| `r::Float64 ` |  learning rate               |
| `n::Float64 ` |  number of observations used |
| `nb::Float64` |  number of batches used      |


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:27](https://github.com/joshday/OnlineStats.jl/tree/40ac77ff87902410a18f9abe4dd009ad4da42d3b/src/summary/quantile.jl#L27)

---

#### Summary
Usage: `Summary(y::Vector)`

| Field           |  Description                 |
|:----------------|:-----------------------------|
| `mean::Float64` |  sample mean                 |
| `var::Float64`  |  sample variance             |
| `max::Float64`  |  sample maximum              |
| `min::Float64`  |  sample minimum              |
| `n:Int64`       |  number of observations used |
| `nb::Int64`     |  number of batches used      |


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:28](https://github.com/joshday/OnlineStats.jl/tree/40ac77ff87902410a18f9abe4dd009ad4da42d3b/src/summary/summary.jl#L28)

---

#### onlinefit
Usage:
```
onlinefit(<<UnivariateDistribution>>, y::Vector)
onlinefit(<<MultivariateDistribution>>, y::Matrix)
```

Online parametric density estimation.  Creates an object of type
`OnlineFit<<Distribution>>`

| Field                          |  Description                          |
|:-------------------------------|:--------------------------------------|
| `d::<<Distribution>>`          | `Distributions.<<Distribution>>`      |
| `stats::<<DistributionStats>>` | `Distributions.<<DistributionStats>>` |
| `n::Int64`                     | number of observations used           |
| `nb::Int64`                    | number of batches used                |


Examples:
```
y1, y2 = randn(100), randn(100)
obj = onlinefit(Normal, y1)
update!(obj, y2)
state(obj)
```



**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:75](https://github.com/joshday/OnlineStats.jl/tree/40ac77ff87902410a18f9abe4dd009ad4da42d3b/src/OnlineStats.jl#L75)

---

#### state
Get current state of estimates with `state(obj)`


**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:46](https://github.com/joshday/OnlineStats.jl/tree/40ac77ff87902410a18f9abe4dd009ad4da42d3b/src/OnlineStats.jl#L46)

---

#### update!
Update `obj` with observations in `newdata` using `update(obj, newdata)`


**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:42](https://github.com/joshday/OnlineStats.jl/tree/40ac77ff87902410a18f9abe4dd009ad4da42d3b/src/OnlineStats.jl#L42)

---

#### n_batches(obj)
Return the number of batches used

**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:33](https://github.com/joshday/OnlineStats.jl/tree/40ac77ff87902410a18f9abe4dd009ad4da42d3b/src/OnlineStats.jl#L33)

---

#### n_obs(obj)
Return the number of observations used

**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:28](https://github.com/joshday/OnlineStats.jl/tree/40ac77ff87902410a18f9abe4dd009ad4da42d3b/src/OnlineStats.jl#L28)


