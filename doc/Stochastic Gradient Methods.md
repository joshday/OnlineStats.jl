# Available Models using Stochastic Gradient Descent and Variants
The interface is standard across the `StochasticGradientStat` types (SGD, Momentum, and Adagrad).  Each takes arguments:

| argument              | description                                                                                |
|:----------------------|:-------------------------------------------------------------------------------------------|
| `x`                   | matrix of predictors                                                                       |
| `y`                   | response vector                                                                            |
| `wgt` (optional)      | Weighting scheme. Defaults to `StochasticWeighting(.51)`                                   |
| `intercept` (keyword) | Should an intercept be included?  Defaults to `true`                                       |
| `model` (keyword)     | One of the models below.  Defaults to `L2Regression()`                                     |
| `penalty` (keyword)   | `NoPenalty()` (default), `L1Penalty(λ [, burnin = 100])` (experimental), or `L2Penalty(λ)` |
| `start` (keyword)     | starting value for β.  Defaults to zeros.                                                  |
| `η` (keyword)         | constant multiplied to gradient                                                            |

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
Penalties on the size of the coefficients can be used to prevent overfitting.  Models are fit without a penalty (`NoPenalty`) by default.<br>Optional penalties are `L1Penalty(λ [, burnin = 100])` (LASSO) and `L2Penalty(λ)` (Ridge).

- `NoPenalty()`
    - No regularization is used.

- `L2Penalty(λ)`  
    - AKA "Ridge" term:  `loss(β) + sumabs2(β)`

- `L1Penalty(λ [, burnin = 100])` (currently only for `SGD`)
    - AKA "Lasso" term: `loss(β) + sumabs(β)`
    - Lasso regularization is a great tool for variable selection, as it sets "small" coefficients to 0.  In general, stochastic gradient methods do not succeed at generating a sparse solution.  To fix this, `SGD` will not update a coefficient that has been set to 0 after seeing `burnin` observations.

# Common Interface

| method          | details                                        |
|:----------------|:-----------------------------------------------|
| `state(o)`      | return coefficients and number of observations |
| `statenames(o)` | names corresponding to `state`: `[:β, :nobs]`  |
| `coef(o)`       | return coefficients                            |
| `predict(o, x)` | `x` can be vector or matrix                    |

## Examples

```julia
# 1) Absolute loss with ridge penalty
# 2) Quantile regression (same as absolute loss if τ = 0.5)
# 3) Ordinary least squares with "slow" decay rate (fast learner)
# 4) Logistic regression with "fast" decay rate (slow learner)
# 5) Support vector machine
# 6) Robust regression with Huber loss and Lasso penalty

o = SGD(x, y, model = L1Regression(), penalty = L2Penalty(.1))

o = SGD(x, y, StochasticWeighting(.7), model = QuantileRegression(0.5))

o = Momentum(x, y, StochasticWeighting(.51), model = L2Regression())

o = Momentum(x, y, StochasticWeighting(.9), model = LogisticRegression())

o = Adagrad(x, y, model = SVMLike(), penalty = L2Penalty(.1))

o = Adagrad(x, y, StochasticWeighting(.7), model = HuberRegression(2.0), penalty = L1Penalty(.01))
```
