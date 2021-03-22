<p align="center">
  <img width="460" src="https://user-images.githubusercontent.com/8075494/111925031-87462b80-8a7d-11eb-98e2-eae044b13a3f.png">
</p>

<p align="center">
  <strong>Online Algorithms for Statistics, Models, and Big Data Viz</strong>
</p>

- ⚡ High-performance single-pass algorithms for statistics and data viz.
- ➕ Updated one observation at a time.
- ✅ Algorithms use O(1) memory.
- 📈 Perfect for streaming and big data.

<p align="center">
  <img width="550" style="border-radius: 5px;" src="https://user-images.githubusercontent.com/8075494/111988551-07ed4200-8ae7-11eb-985e-2ea5f60273ff.gif">
</p>

| Docs | Build | Test | Citation | Dependents |
|:-----|:------|:-----|----------|------------|
| [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://joshday.github.io/OnlineStats.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://joshday.github.io/OnlineStats.jl/latest) | [![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl) | [![codecov](https://codecov.io/gh/joshday/OnlineStats.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/joshday/OnlineStats.jl) | [![DOI](https://joss.theoj.org/papers/10.21105/joss.01816/status.svg)](https://doi.org/10.21105/joss.01816) | [![deps](https://juliahub.com/docs/OnlineStats/deps.svg)](https://juliahub.com/ui/Packages/OnlineStats/G3mU6?t=2) |


## 🚀 Quickstart

```julia
import Pkg

Pkg.add("OnlineStats")

using OnlineStats

o = Series(Mean(), Variance(), Extrema())

fit!(o, 1.0)

fit!(o, randn(10^6))
```

## 📖 Documentation

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://joshday.github.io/OnlineStats.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://joshday.github.io/OnlineStats.jl/latest)

## ✨ Contributing

- Trivial PRs such as fixing typos are very welcome!  
- For nontrivial changes, you'll probably want to first discuss the changes via issue/email/slack with [`@joshday`](https://github.com/joshday).

## ✏️ Authors

- Primary Author: [**Josh Day (@joshday)**](https://github.com/joshday)
- Significant early contributions from [**Tom Breloff (@tbreloff)**](https://github.com/tbreloff)
- Many algorithms developed under mentorship of [**Hua Zhou (@Hua-Zhou)**](https://github.com/Hua-Zhou)

See also the list of [contributors](https://github.com/joshday/OnlineStats.jl/contributors) to OnlineStats.

<a href="https://github.com/joshday/onlinestats.jl/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=joshday/onlinestats.jl" />
</a>
