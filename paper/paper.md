---
title: 'OnlineStats.jl: A Julia package for statistics on data streams'
tags:
  - Julia
  - statistics
  - big data
  - online algorithms
  - streaming data
authors:
  - name: Josh Day
    orcid: 0000-0002-7490-6986
    affiliation: 1
  - name: Hua Zhou
    orcid: 0000-0003-1320-7118
    affiliation: 2
affiliations:
  - name: Loon Analytics, LLC
    index: 1
  - name: UCLA Biostatistics
    index: 2
date: 02 September 2019
bibliography: paper.bib
---

# Summary

The growing prevalence of big and streaming data require a new generation of tools to handle the challenges posed by this new paradigm.  Data often has infinite size in the sense that new observations are continually arriving hourly/weekly/yearly, etc.  Existing offline tools can only operate in finite batches and require re-loading possibly large datasets for seemingly simple tasks such as incorporating a few more observations into an analysis.

``OnlineStats`` is a Julia [@Julia] package that offers a high-performance framework for online algorithms.  It includes a large catalog of algorithms as well as an easily extendable interface.  The paradigm behind ``OnlineStats`` also facilitates embarassingly parallel computations.

# Interface

Each algorithm is associated with its own type (e.g. `Mean`, `Variance`, etc.).  A new statistic/model/visualization requires just a few methods to fit into the ``OnlineStats`` framework.

## Updating

```julia
OnlineStatsBase._fit!(stat, y)
```

The `_fit!` method determines how the statistic is updated with a single observation `y`.  Each OnlineStat is a concrete subtype of `OnlineStat{T}`, where `T` is the type of a single observation.  The `fit!(stat::OnlineStat{T}, y::T)` method simply calls `_fit!`.  When `fit!(stat::OnlineStat{T}, y::S)` is called (where `S` is not a subtype of `T`),  `y` is iterated through and `fit!` is called on each item.

### Update Weights

Many OnlineStats incorporate a weight function that determines the influence of the next observation.  For example, the online update for a mean $\mu^{(t)}$ given its current state $\mu^{(t-1)}$ and new observation $y_t$ is

$$
\mu^{(t)} = (1 - t^{-1}) \mu^{(t-1)} + t^{-1} y_t.
$$

``OnlineStats`` generalizes this update to use weights that are some function of $t$:

$$
\mu^{(t)} = [1 - w(t)] \mu^{(t-1)} + w(t) y_t.
$$

Therefore, $w(t) = t{-1}$ returns the analytical mean and $w(t) = \lambda \; (0 < \lambda < 1)$ returns an exponentially weighted mean.

## Merging

```julia
    OnlineStatsBase._merge!(stat1, stat2)
```

The `_merge!` function merges the state of `stat2` into `stat1`.  This function is optional to implement, as not everything is merge-able.  The default definition prints out a warning that no merging occurred.

## Returning the State

```julia
OnlineStatsBase.value(stat, args...; kw...)
```

The `value` function returns the value of the estimator (optionally determined by positional arguments `args` and keyword arguments `kw`).  Depending on the type, this may need to be calculated from its state.  By default, this returns the first field of the type.

```julia
OnlineStatsBase.nobs(stat)
```

The `nobs` function returns the number of observations that the statistic has seen.  By default this returns the `n` field from the type (`stat.n`).

# Mean Example

The ``Mean`` type provides an understandable full example of how to implement a new algorithm.  The update formula, as previously stated, is:

$$
\mu^{(t)} = [1 - w(t)] \mu^{(t-1)} + w(t) y_t.
$$

The merge formula for two means, $\mu_1^{(t)}$ and $\mu_2^{(s)}$, is

$$
\mu_{merged}^{(t + s)} = [1 - s/(t+s)] \mu_1^{(t)} + [s/(t+s)] \mu_2^{(s)}.
$$

Converting these formulas into ``Julia`` code, we get the following implementation.  Note that `Mean` is parameterized by the data type that stores the mean value so that non-"standard" types such as complex numbers can be used.

```julia
mutable struct Mean{T,W} <: OnlineStat{Number}
    μ::T
    weight::W
    n::Int
end

function Mean(T::Type{<:Number} = Float64; weight = inv)
    Mean(zero(T), weight, 0)
end

function _fit!(o::Mean{T}, x) where {T}
    o.n += 1
    w = T(o.weight(o.n))
    o.μ += w * (x - o.μ)
end

function _merge!(o::Mean, o2::Mean)
    o.n += o2.n
    o.μ += (o2.n / o.n) * (o2.μ - o.μ)
end
```


# References