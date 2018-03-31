| Documentation | Release | Master Build | Test Coverage |
|:-------------:|:-------:|:-----:|:-------------:|
| [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://joshday.github.io/OnlineStats.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://joshday.github.io/OnlineStats.jl/latest) |  [![OnlineStats](http://pkg.julialang.org/badges/OnlineStats_0.6.svg)](http://pkg.julialang.org/?pkg=OnlineStats) | [![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl) [![Build status](https://ci.appveyor.com/api/projects/status/x2t1ey2sgbmow1a4/branch/master?svg=true)](https://ci.appveyor.com/project/joshday/onlinestats-jl/branch/master) | [![codecov](https://codecov.io/gh/joshday/OnlineStats.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/joshday/OnlineStats.jl) |



# OnlineStats

**Online algorithms for statistics.**

**OnlineStats** is a Julia package which provides online algorithms for statistical models.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.


```julia
using OnlineStats

y = randn(1000)

o1 = Mean()
o2 = Mean(weight = x -> .1)

for yi in y
    fit!(o1, yi)
    fit!(o2, yi)
end
```

![](https://user-images.githubusercontent.com/8075494/27964296-c249baec-6305-11e7-89d0-9875d3bdab3e.gif)
