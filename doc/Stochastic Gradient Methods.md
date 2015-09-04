# Stochastic Gradient Models (`SGModel`)

| argument | description          |
|:---------|:---------------------|
| `x`      | matrix of predictors |
| `y`      | response vector      |

| keyword argument | description                                                      |
|:-----------------|:-----------------------------------------------------------------|
| `model`          | one of the ModelDefinition types below, default `L2Regression()` |
| `penalty`        | type of regularization, default: `NoPenalty()`                   |
| `algorithm`      | online algorithm used, default: `SGD()`                          |

The model argument specifies both the link function and loss function to be used.  Options are:

- `L1Regression()`
    - Linear model using absolute loss.  This minimizes `vecnorm(y - X*β, 1)` with respect to β.

- `L2Regression()`
    - Ordinary least squares.  This minimizes `vecnorm(y - X*β, 2)` with respect to β.

- `LogisticRegression()`
    - Maximizes the logistic regression loglikelihood.

- `QuantileRegression(τ)`
    - Predict the conditional τ-th quantile of `y` given `X`

- `SVMLike()`
    - Fits Perceptron (with `penalty = NoPenalty`) or Support Vector Machine (with `penalty = L2Penalty(λ)`)

- `HuberRegression(δ)`
    - Robust regression using Huber loss.

# Penalties/Regularization
Penalties on the size of the coefficients can be used to prevent overfitting.  Models are fit without a penalty (`NoPenalty`) by default.

- `NoPenalty()`
    - No regularization is used.

- `L2Penalty(λ)`  
    - AKA "Ridge" term:  `loss(β) + λ * sumabs2(β)`

- `L1Penalty(λ)`
    - AKA "LASSO" term: `loss(β) + λ * sumabs(β)`
    - NOTE: A major benefit of the LASSO is that it creates a sparse solution.  However, the nature of the SGD/Proxgrad algorithms do NOT generate a sparse solution.  If variable selection/sparse solution is desired, `L1Penalty` should be used with the `RDA` algorithm

- `ElasticNetPenalty(λ, α)`
    - `loss(β) + λ * (α * sumabs(β)` + (1 - α) * sumabs2(β))
    - That is, elastic net is a weighted average between ridge and lasso.  This is the
    same parameterization that the popular R package [glmnet](http://www.inside-r.org/packages/cran/glmnet/docs/glmnet) uses.
    - As for `L1Penalty`, do generate a sparse solution, `RDA` must be the algorithm used.

# Methods

| method          | description                                    |
|:----------------|:-----------------------------------------------|
| `state(o)`      | return coefficients and number of observations |
| `statenames(o)` | names corresponding to `state`: `[:β, :nobs]`  |
| `coef(o)`       | return coefficients                            |
| `predict(o, x)` | `x` can be vector or matrix                    |

## Examples

```julia
o = SGModel(x,y)
o = SGModel(x,y, penalty = L1Penalty(.1))
o = SGModel(x, y, algorithm = RDA(), penalty = ElasticNetPenalty(.1, .5))
o = SGModel(x, y, model = QuantileRegression(.7), algorithm = Proxgrad())
```
