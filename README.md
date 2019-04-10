<img src="https://user-images.githubusercontent.com/8075494/39086572-80874e5a-4561-11e8-9a05-e52b21a3e580.png" width=755>

| Docs | Build | Test |
|:----:|:-----:|:----:|
| [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://joshday.github.io/OnlineStats.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://joshday.github.io/OnlineStats.jl/latest) | [![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl) [![Build status](https://ci.appveyor.com/api/projects/status/x2t1ey2sgbmow1a4/branch/master?svg=true)](https://ci.appveyor.com/project/joshday/onlinestats-jl/branch/master) | [![codecov](https://codecov.io/gh/joshday/OnlineStats.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/joshday/OnlineStats.jl) |

# Online algorithms for statistics

**OnlineStats** is a Julia package which provides online algorithms for statistics, models, and data visualization.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.

![](https://user-images.githubusercontent.com/8075494/46229806-d55a9800-c334-11e8-8616-e4e27e58d66d.gif)



# Quickstart

```julia
import Pkg

Pkg.add("OnlineStats")

using OnlineStats

o = Series(Mean(), Variance(), P2Quantile(), Extrema())

fit!(o, randn(10^6))
```
