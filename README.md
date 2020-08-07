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

| Docs | Build | Test | Citation |
|:-----|:------|:-----|----------|
| [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://joshday.github.io/OnlineStats.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://joshday.github.io/OnlineStats.jl/latest) | [![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl) | [![codecov](https://codecov.io/gh/joshday/OnlineStats.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/joshday/OnlineStats.jl) | [![DOI](https://joss.theoj.org/papers/10.21105/joss.01816/status.svg)](https://doi.org/10.21105/joss.01816) |


## Quickstart

```julia
import Pkg

Pkg.add("OnlineStats")

using OnlineStats

o = Series(Mean(), Variance(), P2Quantile(), Extrema())

fit!(o, 1.0)

fit!(o, randn(10^6))
```

## Documentation

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://joshday.github.io/OnlineStats.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://joshday.github.io/OnlineStats.jl/latest)

## Contributing

- Trivial PRs such as fixing typos are very welcome!  
- For nontrivial changes, you'll probably want to first discuss the changes via issue/email/slack with [`@joshday`](https://github.com/joshday).

## Authors

- Primary Author: [**Josh Day (@joshday)**](https://github.com/joshday)
- Significant early contributions from [**Tom Breloff (@tbreloff)**](https://github.com/tbreloff)

See also the list of [contributors](https://github.com/joshday/OnlineStats.jl/contributors) to OnlineStats.

## License

[MIT](LICENSE)

## Packages Using OnlineStats/[OnlineStatsBase](https://github.com/joshday/OnlineStatsBase.jl)

[![deps](https://juliahub.com/docs/OnlineStats/deps.svg)](https://juliahub.com/ui/Packages/OnlineStats/G3mU6?t=2)

- [ESDL](https://github.com/esa-esdl/ESDL.jl)
- [IndexedTables](https://github.com/JuliaComputing/IndexedTables.jl)
- [JuliaDB](https://github.com/JuliaComputing/JuliaDB.jl)
- [Pathogen](https://github.com/jangevaare/Pathogen.jl)
- [Recombinase](https://github.com/piever/Recombinase.jl)
- [ThreadsX](https://github.com/tkf/ThreadsX.jl)
- [Transducers](https://github.com/JuliaFolds/Transducers.jl)
- [WeightedOnlineStats](https://github.com/gdkrmr/WeightedOnlineStats.jl)