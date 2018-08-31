<img src="https://user-images.githubusercontent.com/8075494/39086572-80874e5a-4561-11e8-9a05-e52b21a3e580.png" width=755>

| Documentation | Release | Master Build | Test Coverage |
|:-------------:|:-------:|:-----:|:-------------:|
| [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://joshday.github.io/OnlineStats.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://joshday.github.io/OnlineStats.jl/latest) |  [![OnlineStats](http://pkg.julialang.org/badges/OnlineStats_0.6.svg)](http://pkg.julialang.org/?pkg=OnlineStats) | [![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl) [![Build status](https://ci.appveyor.com/api/projects/status/x2t1ey2sgbmow1a4/branch/master?svg=true)](https://ci.appveyor.com/project/joshday/onlinestats-jl/branch/master) | [![codecov](https://codecov.io/gh/joshday/OnlineStats.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/joshday/OnlineStats.jl) |

# Online algorithms for statistics

**OnlineStats** is a Julia package which provides online algorithms for statistics, models, and data visualization.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.  


```julia
o1 = Mean()
o2 = Mean(weight = n -> .1)

for yi in y
    fit!(o1, yi)
    fit!(o2, yi)
end
```

![](https://user-images.githubusercontent.com/8075494/38169834-e15b1b32-3542-11e8-8789-e6f6e3296e8e.gif)

# Quickstart

```julia
import Pkg

Pkg.add("OnlineStats")

using OnlineStats

o = Series(Mean(), Variance(), P2Quantile(), Extrema())

fit!(o, randn(10^6))
```

# Tutorials

[https://github.com/joshday/OnlineStatsDemos](https://github.com/joshday/OnlineStatsDemos)