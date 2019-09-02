---
title: 'OnlineStats: A Julia package for statistics on data streams'
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
    orcid: XXXX-XXXX-XXXX-XXXX
    affiliation: 2
affiliations:
  - name: Loon Analytics
    index: 1
  - name: UCLA
    index: 2
date: 02 September 2019
bibliography: paper.bib
---

# Introduction

The growing prevalence of big and streaming data require a new generation of tools to handle the challenges posed by this new paradigm.  Data often has infinite size in the sense that new observations are continually arriving hourly/weekly/yearly, etc.  Existing offline tools can only operate in finite batches and require re-loading possibly large datasets for seemingly simple tasks such as incorporating a few more observations into an analysis.

``OnlineStats`` is a Julia [@Julia] package that offers a high-performance unifying framework for online algorithms.  It is easily extendable and also facilitates the use of embarassingly parallel operations.

# Interface

A new statistic/model/visualization requires just a few methods to fit into the ``OnlineStats`` framework.  Each OnlineStat is its own type.

## Fitting

```
OnlineStatsBase._fit!(stat, y)
```

The `_fit!` method determines how the statistic is updated with a single observation `y`.  Each OnlineStat is a concrete subtype of `OnlineStat{T}`, where `T` is the type of a single observation.  The `fit!(stat::OnlineStat{T}, y::T)` method simply calls `_fit!`.  When `fit!(stat::OnlineStat{T}, y::S)` is called (where `S` is not a subtype of `T`),  `y` is iterated through and `fit!` is called on each item.

## Merging

```
    OnlineStatsBase._merge!(stat1, stat2)
```

The `_merge!` function merges the state of `stat2` into `stat1`.  This function is optional to implement, as not everything is merge-able.  The default definition prints out a warning that no merging occurred.

## Returning the State

```
OnlineStatsBase.value(stat, args...; kw...)
```

The `value` function returns the value of the estimator.  Depending on the type, this may need to be calculated from its state.  By default, this returns the first field of the type.

```
OnlineStatsBase.nobs(stat)
```

The `nobs` function returns the number of observations that the statistic has seen.  By default this returns the `n` field from the type (`stat.n`).

# Examples

## Mean

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