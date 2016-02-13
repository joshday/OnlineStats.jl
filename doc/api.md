# OnlineStats

## Exported

---

<a id="method__cached_state.1" class="lexicon_definition"></a>
#### cached_state(b::OnlineStats.FrozenBootstrap) [¶](#method__cached_state.1)
return the value of interest for each of the `OnlineStat` replicates

*source:*
[OnlineStats/src/streamstats/bootstrap.jl:83](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/streamstats/bootstrap.jl#L83)

---

<a id="method__fit.1" class="lexicon_definition"></a>
#### fit!(o::OnlineStats.OnlineStat{OnlineStats.ScalarInput},  y::AbstractArray{T, 1}) [¶](#method__fit.1)
`fit!(o::OnlineStat, y, b = 1)`

`fit!(o::OnlineStat, x, y, b = 1)`

Include more data for an OnlineStat using batch updates of size `b`.  Batch updates
make more sense for OnlineStats that use stochastic approximation, such as
`StatLearn`, `QuantileMM`, and `NormalMix`.


*source:*
[OnlineStats/src/OnlineStats.jl:192](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/OnlineStats.jl#L192)

---

<a id="method__replicates.1" class="lexicon_definition"></a>
#### replicates(b::OnlineStats.Bootstrap) [¶](#method__replicates.1)
Get the replicates of the `OnlineStat` objects used in the bootstrap

*source:*
[OnlineStats/src/streamstats/bootstrap.jl:111](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/streamstats/bootstrap.jl#L111)

---

<a id="method__sweep.1" class="lexicon_definition"></a>
#### sweep!(A::AbstractArray{Float64, 2},  k::Integer) [¶](#method__sweep.1)
### `sweep!(A, k, inv = false)`

Symmetric sweep of the matrix `A` on element `k`.


*source:*
[OnlineStats/src/modeling/sweep.jl:6](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/modeling/sweep.jl#L6)

---

<a id="method__sweep.2" class="lexicon_definition"></a>
#### sweep!(A::AbstractArray{Float64, 2},  k::Integer,  inv::Bool) [¶](#method__sweep.2)
### `sweep!(A, k, inv = false)`

Symmetric sweep of the matrix `A` on element `k`.


*source:*
[OnlineStats/src/modeling/sweep.jl:6](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/modeling/sweep.jl#L6)

---

<a id="method__sweep.3" class="lexicon_definition"></a>
#### sweep!(A::AbstractArray{Float64, 2},  k::Integer,  v::AbstractArray{Float64, 1}) [¶](#method__sweep.3)
### `sweep!(A, k, v, inv = false)`

Symmetric sweep of the matrix `A` on element `k` using vector `v` as storage to
avoid memory allocation.  This requires `length(v) == size(A, 1)`.  Both `A` and `v`
will be overwritten.

`inv = true` will perform an inverse sweep.  Only the upper triangle is read and swept.


*source:*
[OnlineStats/src/modeling/sweep.jl:51](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/modeling/sweep.jl#L51)

---

<a id="method__sweep.4" class="lexicon_definition"></a>
#### sweep!(A::AbstractArray{Float64, 2},  k::Integer,  v::AbstractArray{Float64, 1},  inv::Bool) [¶](#method__sweep.4)
### `sweep!(A, k, v, inv = false)`

Symmetric sweep of the matrix `A` on element `k` using vector `v` as storage to
avoid memory allocation.  This requires `length(v) == size(A, 1)`.  Both `A` and `v`
will be overwritten.

`inv = true` will perform an inverse sweep.  Only the upper triangle is read and swept.


*source:*
[OnlineStats/src/modeling/sweep.jl:51](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/modeling/sweep.jl#L51)

---

<a id="method__value.1" class="lexicon_definition"></a>
#### value(o::OnlineStats.OnlineStat{I<:OnlineStats.Input}) [¶](#method__value.1)
`value(o::OnlineStat)`.  The associated value of an OnlineStat.

*source:*
[OnlineStats/src/OnlineStats.jl:263](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/OnlineStats.jl#L263)

---

<a id="type__bernoullibootstrap.1" class="lexicon_definition"></a>
#### OnlineStats.BernoulliBootstrap{S<:OnlineStats.OnlineStat{I<:OnlineStats.Input}} [¶](#type__bernoullibootstrap.1)
`BernoulliBootstrap(o, f, r)`

Create a double-or-nothing bootstrap using `r` replicates of OnlineStat `o` for estimate `f(o)`

Example: `BernoulliBootstrap(Mean(), mean, 1000)`


*source:*
[OnlineStats/src/streamstats/bootstrap.jl:13](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/streamstats/bootstrap.jl#L13)

---

<a id="type__boundedexponentialweight.1" class="lexicon_definition"></a>
#### OnlineStats.BoundedExponentialWeight [¶](#type__boundedexponentialweight.1)
`BoundedExponentialWeight(minstep)`.  Once equal weights reach `minstep`, hold weights constant.

*source:*
[OnlineStats/src/OnlineStats.jl:87](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/OnlineStats.jl#L87)

---

<a id="type__covmatrix.1" class="lexicon_definition"></a>
#### OnlineStats.CovMatrix{W<:OnlineStats.Weight} [¶](#type__covmatrix.1)
Covariance matrix

*source:*
[OnlineStats/src/summary.jl:113](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/summary.jl#L113)

---

<a id="type__diffs.1" class="lexicon_definition"></a>
#### OnlineStats.Diffs{T<:Real} [¶](#type__diffs.1)
Track the last values and the last differences for multiple series

*source:*
[OnlineStats/src/summary.jl:347](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/summary.jl#L347)

---

<a id="type__diff.1" class="lexicon_definition"></a>
#### OnlineStats.Diff{T<:Real} [¶](#type__diff.1)
Track the last value and the last difference

*source:*
[OnlineStats/src/summary.jl:319](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/summary.jl#L319)

---

<a id="type__equalweight.1" class="lexicon_definition"></a>
#### OnlineStats.EqualWeight [¶](#type__equalweight.1)
All observations weighted equally.

*source:*
[OnlineStats/src/OnlineStats.jl:61](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/OnlineStats.jl#L61)

---

<a id="type__exponentialweight.1" class="lexicon_definition"></a>
#### OnlineStats.ExponentialWeight [¶](#type__exponentialweight.1)
`ExponentialWeight(λ)`.  Most recent observation has a constant weight of λ.

*source:*
[OnlineStats/src/OnlineStats.jl:71](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/OnlineStats.jl#L71)

---

<a id="type__extrema.1" class="lexicon_definition"></a>
#### OnlineStats.Extrema{W<:OnlineStats.Weight} [¶](#type__extrema.1)
Extrema (maximum and minimum).  Ignores `Weight`.

*source:*
[OnlineStats/src/summary.jl:163](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/summary.jl#L163)

---

<a id="type__fitcategorical.1" class="lexicon_definition"></a>
#### OnlineStats.FitCategorical{W<:OnlineStats.Weight, T} [¶](#type__fitcategorical.1)
`FitCategorical(y)`

Find the proportions for each unique input.  Categories are sorted by proportions.


*source:*
[OnlineStats/src/distributions.jl:40](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/distributions.jl#L40)

---

<a id="type__frozenbootstrap.1" class="lexicon_definition"></a>
#### OnlineStats.FrozenBootstrap [¶](#type__frozenbootstrap.1)
Frozen bootstrap object are generated when two bootstrap distributions are combined, e.g., if they are differenced.

*source:*
[OnlineStats/src/streamstats/bootstrap.jl:77](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/streamstats/bootstrap.jl#L77)

---

<a id="type__hardthreshold.1" class="lexicon_definition"></a>
#### OnlineStats.HardThreshold [¶](#type__hardthreshold.1)
After `burnin` observations, coefficients will be set to zero if they are less
than `ϵ`.


*source:*
[OnlineStats/src/modeling/statlearnextensions.jl:8](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/modeling/statlearnextensions.jl#L8)

---

<a id="type__hyperloglog.1" class="lexicon_definition"></a>
#### OnlineStats.HyperLogLog [¶](#type__hyperloglog.1)
`HyperLogLog(b)`

Approximate count of distinct elements.  `HyperLogLog` differs from other OnlineStats
in that any input to `fit!(o::HyperLogLog, input)` is considered a singleton.  Thus,
a vector of inputs must be similar to:

```julia
o = HyperLogLog(4)
for yi in y
    fit!(o, yi)
end
```


*source:*
[OnlineStats/src/streamstats/hyperloglog.jl:39](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/streamstats/hyperloglog.jl#L39)

---

<a id="type__learningrate.1" class="lexicon_definition"></a>
#### OnlineStats.LearningRate [¶](#type__learningrate.1)
`LearningRate(r; minstep = 0.0)`.

Weight at update `t` is `1 / t ^ r`.  Compare to `LearningRate2`.


*source:*
[OnlineStats/src/OnlineStats.jl:107](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/OnlineStats.jl#L107)

---

<a id="type__learningrate2.1" class="lexicon_definition"></a>
#### OnlineStats.LearningRate2 [¶](#type__learningrate2.1)
LearningRate2(γ, c = 1.0; minstep = 0.0).

Weight at update `t` is `γ / (1 + γ * c * t)`.  Compare to `LearningRate`.


*source:*
[OnlineStats/src/OnlineStats.jl:135](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/OnlineStats.jl#L135)

---

<a id="type__means.1" class="lexicon_definition"></a>
#### OnlineStats.Means{W<:OnlineStats.Weight} [¶](#type__means.1)
Mean vector of a data matrix, similar to `mean(x, 1)`

*source:*
[OnlineStats/src/summary.jl:34](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/summary.jl#L34)

---

<a id="type__mean.1" class="lexicon_definition"></a>
#### OnlineStats.Mean{W<:OnlineStats.Weight} [¶](#type__mean.1)
Univariate Mean

*source:*
[OnlineStats/src/summary.jl:13](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/summary.jl#L13)

---

<a id="type__moments.1" class="lexicon_definition"></a>
#### OnlineStats.Moments{W<:OnlineStats.Weight} [¶](#type__moments.1)
Univariate, first four moments.  Provides `mean`, `var`, `skewness`, `kurtosis`

*source:*
[OnlineStats/src/summary.jl:281](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/summary.jl#L281)

---

<a id="type__normalmix.1" class="lexicon_definition"></a>
#### OnlineStats.NormalMix{W<:OnlineStats.Weight} [¶](#type__normalmix.1)
`NormalMix(k, wgt; start)`

Normal Mixture of `k` components via an online EM algorithm.  `start` is a keyword
argument specifying the initial parameters.

If the algorithm diverges, try using a different `start`.

Example:

`NormalMix(k, wgt; start = MixtureModel(Normal, [(0, 1), (3, 1)]))`


*source:*
[OnlineStats/src/normalmix.jl:13](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/normalmix.jl#L13)

---

<a id="type__poissonbootstrap.1" class="lexicon_definition"></a>
#### OnlineStats.PoissonBootstrap{S<:OnlineStats.OnlineStat{I<:OnlineStats.Input}} [¶](#type__poissonbootstrap.1)
`PoissonBootstrap(o, f, r)`

Create a poisson bootstrap using `r` replicates of OnlineStat `o` for estimate `f(o)`

Example: `PoissonBootstrap(Mean(), mean, 1000)`


*source:*
[OnlineStats/src/streamstats/bootstrap.jl:48](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/streamstats/bootstrap.jl#L48)

---

<a id="type__quantreg.1" class="lexicon_definition"></a>
#### OnlineStats.QuantReg{W<:OnlineStats.Weight} [¶](#type__quantreg.1)
Online MM Algorithm for Quantile Regression.

*source:*
[OnlineStats/src/modeling/quantreg.jl:2](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/modeling/quantreg.jl#L2)

---

<a id="type__quantilemm.1" class="lexicon_definition"></a>
#### OnlineStats.QuantileMM{W<:OnlineStats.Weight} [¶](#type__quantilemm.1)
Approximate quantiles via an online MM algorithm

*source:*
[OnlineStats/src/summary.jl:227](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/summary.jl#L227)

---

<a id="type__quantilesgd.1" class="lexicon_definition"></a>
#### OnlineStats.QuantileSGD{W<:OnlineStats.Weight} [¶](#type__quantilesgd.1)
Approximate quantiles via stochastic gradient descent

*source:*
[OnlineStats/src/summary.jl:187](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/summary.jl#L187)

---

<a id="type__statlearncv.1" class="lexicon_definition"></a>
#### OnlineStats.StatLearnCV{T<:Real, S<:Real, W<:OnlineStats.Weight} [¶](#type__statlearncv.1)
`StatLearnCV(o::StatLearn, xtest, ytest)`

Automatically tune the regularization parameter λ for `o` by minimizing loss on
test data `xtest`, `ytest`.


*source:*
[OnlineStats/src/modeling/statlearnextensions.jl:69](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/modeling/statlearnextensions.jl#L69)

---

<a id="type__statlearnsparse.1" class="lexicon_definition"></a>
#### OnlineStats.StatLearnSparse{S<:OnlineStats.AbstractSparsity} [¶](#type__statlearnsparse.1)
### Enforce sparsity on a `StatLearn` object

`StatLearnSparse(o::StatLearn, s::AbstractSparsity)`


*source:*
[OnlineStats/src/modeling/statlearnextensions.jl:23](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/modeling/statlearnextensions.jl#L23)

---

<a id="type__statlearn.1" class="lexicon_definition"></a>
#### OnlineStats.StatLearn{A<:OnlineStats.Algorithm, M<:OnlineStats.ModelDef, P<:OnlineStats.Penalty, W<:OnlineStats.Weight} [¶](#type__statlearn.1)
### Online Statistical Learning
- `StatLearn(p)`
- `StatLearn(x, y)`
- `StatLearn(x, y, b)`

The model is defined by:

#### `ModelDef`

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
    - Perceptron with `NoPenalty`. SVM with `L2Penalty`.
- `HuberRegression(δ)`
    - Robust Huber loss

#### `Penalty`
- `NoPenalty()`
    - No penalty.  Default.
- `L2Penalty(λ)`
    - Ridge regularization
- `L1Penalty(λ)`
    - LASSO regularization
- `ElasticNetPenalty(λ, α)`
    - Ridge/LASSO weighted average.  `α = 0` is Ridge, `α = 1` is LASSO.

#### `Algorithm`
- `SGD()`
    - Stochastic gradient descent.  Default.
- `AdaGrad()`
    - Adaptive gradient method. Ignores `Weight`.
- `AdaDelta()`
    - Extension of AdaGrad.  Ignores `Weight`.
- `RDA()`
    - Regularized dual averaging with ADAGRAD.  Ignores `Weight`.
- `MMGrad()`
    - Experimental online MM gradient method.
- `AdaMMGrad()`
    - Experimental adaptive online MM gradient method.  Ignores `Weight`.


### Example:
`StatLearn(x, y, 10, LearningRate(.7), RDA(), SVMLike(), L2Penalty(.1))`


*source:*
[OnlineStats/src/modeling/statlearn.jl:133](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/modeling/statlearn.jl#L133)

---

<a id="type__variances.1" class="lexicon_definition"></a>
#### OnlineStats.Variances{W<:OnlineStats.Weight} [¶](#type__variances.1)
Variance vector of a data matrix, similar to `var(x, 1)`

*source:*
[OnlineStats/src/summary.jl:78](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/summary.jl#L78)

---

<a id="type__variance.1" class="lexicon_definition"></a>
#### OnlineStats.Variance{W<:OnlineStats.Weight} [¶](#type__variance.1)
Univariate Variance

*source:*
[OnlineStats/src/summary.jl:55](https://github.com/joshday/OnlineStats.jl/tree/5dda345c96a7d452b97f1200cfd1d66975273189/src/summary.jl#L55)

