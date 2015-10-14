# Stochastic (Sub)gradient Models

The `SGModel` type is a framework for fitting a wide variety of models that are based on stochastic estimates of a (sub)gradient.  An `SGModel` is defined by three things:

1. [Model](SGModel.md#Models)
1. [Penalty](SGModel.md#Penalties/Regularization)
1. [Algorithm](SGModel.md#Algorithms)

# Usage

```julia
SGModel(x, y; model = L2Regression(), penalty = NoPenalty(), algorithm = SGD())
```

| arguments | description          |
|:----------|:---------------------|
| `x`       | matrix of predictors |
| `y`       | response vector      |

| keyword arguments | description                                                         |
|:------------------|:--------------------------------------------------------------------|
| `model`           | one of the ModelDefinition types below, default `L2Regression()`    |
| `penalty`         | type of regularization, default: `NoPenalty()`                      |
| `algorithm`       | online algorithm used, default: `ProxGrad()`                        |
| `intercept`       | `Bool`.  Should intercept be included in the model?  Default `true` |

# Models

The model argument specifies both the link function and loss function to be used.  Options are:

- `L1Regression()`
    - Linear model using absolute loss.  This minimizes `vecnorm(y - X*β, 1)` with respect to β.

- `L2Regression()`
    - Ordinary least squares.  This minimizes `vecnorm(y - X*β, 2)` with respect to β.

- `LogisticRegression()`
    - Maximizes the logistic regression loglikelihood.

- `PoissonRegression`
    - Maximizes the poisson regression loglikelihood.
    - This is unstable with SGD.  It is recommended you use ProxGrad or RDA.

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
    - NOTE: A major benefit of the LASSO is that it creates a sparse solution.  However, the nature of the SGD/ProxGrad algorithms do NOT generate a sparse solution.  If variable selection/sparse solution is desired, `L1Penalty` should be used with the `RDA` algorithm

- `ElasticNetPenalty(λ, α)`
    - `loss(β) + λ * (α * sumabs(β) + (1 - α) * sumabs2(β))`
    - That is, elastic net is a weighted average between ridge and lasso.  This is the
    same parameterization that the popular R package [glmnet](http://www.inside-r.org/packages/cran/glmnet/docs/glmnet) uses.
    - As for `L1Penalty`, to generate a sparse solution, `RDA` must be the algorithm used.

# Algorithms

- `SGD(η = 1.0, r = .5)`  
    - Stochastic (sub)gradient descent using weights `γ = η * nobs ^ -r`
    - `η` is a constant step size (> 0)
    - `r` is a learning rate parameter (between 0 and 1).  Theoretically, unless
    doing Polyak-Juditsky averaging, this shouldn't be less than 0.5.  A smaller `r`
    puts more value on new observations.

- `ProxGrad(η = 1.0)`
    - Stochastic Proximal Subradient Method w/ ADAGRAD
    - `η` is a constant step size (> 0)
    - Weights are automatically determined by ADAGRAD.
    - Penalties are handled with prox operators

- `RDA(η = 1.0)`
    - Regularized Dual Averaging w/ ADAGRAD
    - `η` is a constant step size

# Methods

| method                    | description                 |
|:--------------------------|:----------------------------|
| `StatsBase.coef(o)`       | return coefficients         |
| `StatsBase.predict(o, x)` | `x` can be Vector or Matrix |

# SGModel Examples

```julia
o = SGModel(x,y)
o = SGModel(x, y, penalty = L1Penalty(.1))
o = SGModel(x, y, algorithm = RDA(), penalty = ElasticNetPenalty(.1, .5))
o = SGModel(x, y, model = QuantileRegression(.7), algorithm = ProxGrad())
```


# Cross Validation

The `SGModelCV` type can be used to automatically learn the optimal penalty parameter `λ` for minimizing the MSE of a test set.

This type is experimental, but very promising.

```julia
o = SGModel(size(x, 2), penalty = L1Penalty(.1))
o = SGModelCV(o, xtest, ytest; λrate = LearningRate(), burnin = 1000)
update!(o, x, y)
```

After reaching `burnin` observations, updating a single observation will include adjusting (+/-) the penalty parameter by a step size determined by `λrate`.  The `λ` which minimizes the loss on the test set is then chosen.
