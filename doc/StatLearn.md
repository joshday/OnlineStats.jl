# StatLearn

Approximate solutions to statistical learning problems using online algorithms.  `StatLearn` has extremely fast fitting times.  Number of operations per update is linear with respect to the number of parameters.

`StatLearn` provides multiple algorithms for problems of the form

$$\frac{1}{T}\sum_{t=1}^T f_t(\beta) + \lambda \; g(\beta),$$

where $f_t$ is the loss at time/update $t$, $g$ is a penalty/regularization term, and $\lambda$ is the regularization parameter.

## StatLearn is parameterized by three main types

!!! note
    The idea is to use `Algorithm` to solve problems of the form `ModelDefinition + Penalty`.

### ModelDefinition
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
    - For data in {-1, 1}.  With `NoPenalty`, this is a perceptron.  With `RidgePenalty`, this is a support vector machine.
- `HuberRegression(δ)`
    - Robust Huber loss

### Penalty
- `NoPenalty()`
    - No penalty.  Default.
- `RidgePenalty(λ)`
    - Ridge regularization
- `LassoPenalty(λ)`
    - LASSO regularization
- `ElasticNetPenalty(λ, α)`
    - Weighted average of Ridge and LASSO.  `α = 0` is Ridge, `α = 1` is LASSO.

### Algorithm
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


## Learning rates and batch sizes matter

Using mini-batches, gradient estimates are less noisy.  The trade-off,
of course, is that fewer updates occur.

```julia
o1 = StatLearn(x, y, SGD(), LearningRate(.6))      # batch size = 1
o2 = StatLearn(x, y, 10, LearningRate(.6), SGD())  # batch size = 10
```
!!! note
    Any order of `Weight`, `Algorithm`, `ModelDefinition`, and `Penalty` arguments are
    accepted by `StatLearn`.
