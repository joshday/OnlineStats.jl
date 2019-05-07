<p align="center">
  <img width="460" src="https://user-images.githubusercontent.com/8075494/57313750-3d890d80-70be-11e9-99c9-b3fe0de6ea81.png">
</p>

<table align="center">
<tr>
    <th>Docs</th>
    <th>Build</th>
    <th>Test</th>
</tr>
<tr>
    <td>
        <a href="https://joshday.github.io/OnlineStats.jl/stable">
            <img src="https://img.shields.io/badge/docs-stable-blue.svg">
        </a>
        <br>
        <a href="https://joshday.github.io/OnlineStats.jl/latest">
            <img src="https://img.shields.io/badge/docs-latest-blue.svg">
        </a>
    </td>
    <td>
        <a href="https://travis-ci.org/joshday/OnlineStats.jl">
            <img src="https://travis-ci.org/joshday/OnlineStats.jl.svg">
        </a>
        <br>
        <a href="https://ci.appveyor.com/project/joshday/onlinestats-jl/branch/master">
            <img src="https://ci.appveyor.com/api/projects/status/x2t1ey2sgbmow1a4/branch/master?svg=true">
        </a>
    </td>
    <td>
        <a href="https://codecov.io/gh/joshday/OnlineStats.jl">
            <img src="https://codecov.io/gh/joshday/OnlineStats.jl/branch/master/graph/badge.svg">
        </a>
    </td>
</tr>
</table>


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
