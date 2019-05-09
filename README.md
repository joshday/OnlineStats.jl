<p align="center">
  <img width="460" src="https://user-images.githubusercontent.com/8075494/57313750-3d890d80-70be-11e9-99c9-b3fe0de6ea81.png">
</p>

<p align="center">
  <strong>Online Algorithms for Statistics, Models, and Big Data Viz</strong>
</p>

Online algorithms are well suited for streaming data or when data is too large to hold in memory.  **OnlineStats** processes observations one by one and all **algorithms use O(1) memory**.

<p align="center">
  <img width="550" src="https://user-images.githubusercontent.com/8075494/46229806-d55a9800-c334-11e8-8616-e4e27e58d66d.gif">
</p>

| Docs | Build | Test |
|:-----|:------|:-----|
| [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://joshday.github.io/OnlineStats.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://joshday.github.io/OnlineStats.jl/latest) | [![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl) [![Build status](https://ci.appveyor.com/api/projects/status/x2t1ey2sgbmow1a4/branch/master?svg=true)](https://ci.appveyor.com/project/joshday/onlinestats-jl/branch/master) | [![codecov](https://codecov.io/gh/joshday/OnlineStats.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/joshday/OnlineStats.jl) |


## Quickstart

```julia
import Pkg

Pkg.add("OnlineStats")

using OnlineStats

o = Series(Mean(), Variance(), P2Quantile(), Extrema())

fit!(o, randn(10^6))
```

## Documentation

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://joshday.github.io/OnlineStats.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://joshday.github.io/OnlineStats.jl/latest)

## Contributing

When contributing to OnlineStats, trivial PRs like documentation typos are very welcome!  For nontrivial changes, please first discuss the change you wish to make via issue/email/slack with @joshday.

## Authors

- Primary Author: [**Josh Day (@joshday)**](https://github.com/joshday)
- Significant early contributions from [**Tom Breloff (@tbreloff)**](https://github.com/tbreloff)

See also the list of [contributors](https://github.com/joshday/OnlineStats.jl/contributors) to OnlineStats.

## License

OnlineStats is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.