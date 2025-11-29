# Statistical Learning

The `StatLearn` (short for statistical learning) OnlineStat uses stochastic approximation methods to estimate models that take the form:

```math
\hat\beta = \argmin_\beta \frac{1}{n} \sum_i f(y_i, x_i'\beta) + \sum_j \lambda_j g(\beta_j),
```

where

- ``f`` is a **loss function** of a response variable and linear preditor.
- ``\lambda_j``'s are nonnegative regularization parameters.
- ``g`` is a **penalty function**.

For example, [LASSO Regression](https://en.wikipedia.org/wiki/Lasso_(statistics)) fits this form with:

- ``f(y_i, x_i'\beta) = \frac{1}{2}(y_i - x_i'\beta) ^ 2``
- ``g(\beta_j) = |\beta_j|``

OnlineStats implements interchangeable loss and penalty functions to use for both regression and classification problems.  See the [`StatLearn`](@ref) docstring for details.

## Stochastic Approximation

An important note is that [`StatLearn`](@ref) is unable to estimate coefficients exactly (For precision in regression problems, see [`LinReg`](@ref)).  The upside is that it makes estimating certain models *possible* in an online fashion.

For example, it is **not possible** to get the same coefficients for logistic regression from an O(1)-memory *online* algorithm as you would get from its *offline* counterpart.  This is because the logistic regression likelihood's [sufficient statistics](https://en.wikipedia.org/wiki/Sufficient_statistic) scale with the number of observations.

**All this to say: `StatLearn` lets you do things that would otherwise not be possible at the cost of returning noisy estimates.**

## Algorithms

Besides the loss and penalty functions, you can also plug in a variety of fitting algorithms to `StatLearn`.  Some of these methods are based on the stochastic gradient (gradient of loss evaluated on a single observation).  Other methods are based on the [majorization-minimization (MM)](https://en.wikipedia.org/wiki/MM_algorithm) principle[^1], which offers some guarantees on numerical stability (sometimes at the cost of slower learning).

[^1]: At the moment, the only place to read about the stochastic MM algorithms in detail is [Josh Day's dissertation](https://en.wikipedia.org/wiki/MM_algorithm).  Josh is working on an easier-to-digest introduction to these methods and is also happy to discuss them through GitHub issue/email.

It is a good idea to test out different algorithms on a sample of your dataset.  Plotting the coefficients over time can give you an idea of the stability of the estimates.  Use [`Trace`](@ref), a wrapper around an OnlineStat, to automatically take equally-spaced snapshots of an OnlineStat's state.  Keep in mind the early observations will cause bigger jumps in the cofficients than later observations (based on the learning rate; see [Weights](@ref).  To add further complexity, learning rates (supplied by the `rate` keyword argument) do not affect each algorithm's learning uniformly.  You may need to test different combinations of algorithm/learning rate to find an "optimal" pairing.

```@example statsmodels
using OnlineStats, Plots

# fake data
x = rand(Bool, 1000, 10)
y = x * (1:10) + 10randn(1000)

rate = LearningRate(.8)

o = Trace(StatLearn(SGD(), OnlineStats.l2regloss; rate))
o2 = Trace(StatLearn(MSPI(), OnlineStats.l2regloss; rate))

itr = zip(eachrow(x), y)

fit!(o, itr)
fit!(o2, itr)

plot(
    plot(o, xlab="Nobs", title="SGD Coefficients", lab=nothing),
    plot(o2, xlab="Nobs", title="MSPI Coefficients", lab=nothing),
    link=:y
)
```
