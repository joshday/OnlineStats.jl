[![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl)
[![Coverage Status](https://coveralls.io/repos/joshday/OnlineStats.jl/badge.svg?branch=master)](https://coveralls.io/r/joshday/OnlineStats.jl?branch=master)

# OnlineStats

Online algorithms for statistics.  See [Examples](doc/examples) and [Implementation Progress](src)


## Types 

A simplified `OnlineStats` type structure:

```julia

type OnlineStatistic
	estimate         # current estimate
	sufficient_stat  # values needed to update estimate
	n                # Number of observations used
	weighting        # How should new observations be weighted
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
- `DataFrame(o)`
	- construct a `DataFrame` from `o` with column names `statenames(o)` and values `state(o)`
- `push!(df, o)` 
	- add `state(o)` to a new row of `df` 





## Thank you
I often find myself looking through the source code of the following packages.  

- [StreamStats](https://github.com/johnmyleswhite/StreamStats.jl)
- [GLM](https://github.com/JuliaStats/GLM.jl)  
- [Distributions](https://github.com/JuliaStats/Distributions.jl)  
- [DataFrames](https://github.com/JuliaStats/DataFrames.jl)
