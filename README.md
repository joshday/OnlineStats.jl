[![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl)
[![Coverage Status](https://coveralls.io/repos/joshday/OnlineStats.jl/badge.svg?branch=josh)](https://coveralls.io/r/joshday/OnlineStats.jl?branch=josh)

# OnlineStats

Online algorithms for statistics.  See [Examples and Implementation Progress](src/README)


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
- `DataFrame(o)`
	- construct a `DataFrame` from `o` with column names `statenames(o)` and values `state(o)`
- `push!(df, o)` 
	- add `state(o)` to a new row of `df` 
- `tracedata(o, b, y...; batch = false)`
	- Create Dataframe of trace results from object `o` using batch size `b` and data `y...`.  If `batch = true`, updates will be done with `updatebatch!` instead of `update`.  Each row of the Dataframe is a snapshow of the object.
- `unpack_vectors(df)` 
	- If `tracedata` is used on a vector-valued statistic, `unpack_vectors` is used to give each value of the vector its own row





## Thank you
I often find myself looking through the source code of the following packages.  

- [StreamStats](https://github.com/johnmyleswhite/StreamStats.jl)
- [GLM](https://github.com/JuliaStats/GLM.jl)  
- [Distributions](https://github.com/JuliaStats/Distributions.jl)  
- [DataFrames](https://github.com/JuliaStats/DataFrames.jl)
