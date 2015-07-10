[![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl)
[![Coverage Status](https://coveralls.io/repos/joshday/OnlineStats.jl/badge.svg?branch=josh)](https://coveralls.io/r/joshday/OnlineStats.jl?branch=josh)

# OnlineStats

Online algorithms for statistics.  See [Implementation Progress](src/README.md)

Install with `Pkg.clone("https://github.com/joshday/OnlineStats.jl")`

## Types

A simplified `OnlineStats` type structure:

```julia

type OnlineStatistic{W <: Weighting}
	estimate         # current estimate
	sufficient_stat  # values needed to update estimate
	n                # Number of observations used
	weighting::W     # How should new observations be weighted
end
```

## Exported functions

- `state(o)`
	- return vector of current estimates
- `statenames(o)`
	- return corresponding names to `state(o)`
- `update!(o, y)`
	- update estimate in `o` using data `y` with weighting scheme defined by `o.weighting`
	- Observations are weighted in order of appearance
- `updatebatch!(o, y)`
	- update estimate in `o` using data `y` with weighting scheme defined by 	`o.weighting`
	- Each observation gets equal weight
- `nobs(o)`
	- return the number of observations
- `onlinefit!(o, b, args..., batch = true)`
	- Run through the data `args...` calling `update!(o)`/`updatebatch!()` on minibatches of size `b`



## Thank you
I often find myself looking through the source code of the following packages.  

- [StreamStats](https://github.com/johnmyleswhite/StreamStats.jl)
- [GLM](https://github.com/JuliaStats/GLM.jl)  
- [Distributions](https://github.com/JuliaStats/Distributions.jl)  
- [DataFrames](https://github.com/JuliaStats/DataFrames.jl)
