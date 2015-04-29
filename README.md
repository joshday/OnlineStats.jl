[![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl)
[![Coverage Status](https://coveralls.io/repos/joshday/OnlineStats.jl/badge.svg?branch=master)](https://coveralls.io/r/joshday/OnlineStats.jl?branch=master)

# OnlineStats

Online algorithms for statistics.  See [Examples](doc/examples) and [Implementation Progress](src)


## Types 

A simplified `OnlineStats` type structure:

```
type OnlineStatistic
	estimate         # current estimate
	sufficient_stat  # values needed to update estimate
	n                # Number of observations used
	weighting        # How should new observations be weighted
end
```

## Exported functions

| Function Name     |   Return Value                                     |
|-------------------|----------------------------------------------------|
| `state(obj)`      | vector of current estimates                        |
| `statenames(obj)` | corresponding names to `state(obj)`                |
| `update!(obj, y)` | update estimates in `obj` with data `y`            |
| `nobs(obj)`       | number of observations                             |
| `DataFrame(obj)`  | construct a `DataFrame` from `obj`                 |
| `push!(df, obj)`  | add new row(s) to `df` with current state of `obj` |




## Thank you
I often find myself looking through the source code of the following packages.  

- [StreamStats](https://github.com/johnmyleswhite/StreamStats.jl)
- [GLM](https://github.com/JuliaStats/GLM.jl)  
- [Distributions](https://github.com/JuliaStats/Distributions.jl)  
- [DataFrames](https://github.com/JuliaStats/DataFrames.jl)
