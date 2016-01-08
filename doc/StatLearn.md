# `StatLearn`

Approximate solutions to statistical learning problems.  `StatLearn` has extremely
fast fitting times to remove training time bottlenecks.

### StatLearn types are defined by three things

- `ModelDef`
    - `L2Regression()`
        - Squared error loss.  Default.
    - `L1Regression()`
        - Absolute loss
    - `LogisticRegression()`
        - Model for data in {0, 1}
    - `PoissonRegression()`
        - Model count data {0, 1, 2, 3, ...}
    - `QuantileRegression(τ)`
        - Model conditional quantiles
    - `SVMLike()`
        - With `NoPenalty()`, this is a perceptron.  With `L2Penalty()`, this is a support vector machine.
    - `HuberRegression(δ)`
        - Robust Huber loss

- `Penalty`
    - `NoPenalty()`
        - No penalty.  Default.
    - `L2Penalty()`
        - Ridge regularization
    - `L1Penalty()`
        - LASSO regularization
    - `ElasticNetPenalty(α)`
        - Weighted average of Ridge and LASSO.  `α = 0` is Ridge, `α = 1` is LASSO.

- `Algorithm`
    - `SGD()`
        - Stochastic gradient descent.  Default.
    - `AdaGrad()`
        - Adaptive gradient method. Ignores `Weight`.
    - `AdaDelta()`
        - Essentially AdaGrad with momentum and altered Hessian approximation.  Ignores `Weight`.
    - `RDA()`
        - Regularized dual averaging with ADAGRAD.  Ignores `Weight`.
    - `MMGrad()`
        - Experimental online MM gradient method.
    - `AdaMMGrad()`
        - Experimental adaptive online MM gradient method.


### Learning rates and batch sizes matter

Using mini-batches, we can get gradient estimates with less noise.  The trade-off,
of course, is that we have fewer updates to work with.

```julia
o = Stat

```
