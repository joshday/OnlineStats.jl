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

# Summary

OnlineStats is a Julia [@Julia] package that offers a unifying framework of online algorithms for statistics, modeling, and data visualizations.  Each algorithm follows a common interface that defines an extensible framework.  A new statistic/model/visualization requires just a few methods to fit into the OnlineStats framework:

- `OnlineStatsBase._fit!(stat, y)`
  - Update the "sufficient statistics" of the estimator from a single observation `y`.
- `OnlineStatsBase._merge!(stat1, stat2)`
  - Merge `stat2` into `stat1`. This is an optional method, as not everything is merge-able.  By default, a warning will occur.
- `OnlineStatsBase.value(stat, args...; kw...)`
  - Calculate the value of the estimator from the "sufficient statistics". By default, this returns the first field of the type.
- `OnlineStatsBase.nobs(stat)`
  - Return the number of observations. By default, this returns `stat.n`.



# References