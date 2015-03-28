[![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl)
[![Coverage Status](https://coveralls.io/repos/joshday/OnlineStats.jl/badge.svg?branch=master)](https://coveralls.io/r/joshday/OnlineStats.jl?branch=master)

# OnlineStats

Online algorithms for statistics.  See [Examples](doc/examples) and [Implementation Progress](src)

The driving function in this package is  

```update!(obj, newdata)```  
- `obj`: subtype of `OnlineStat`  
- `newdata`: new observations (typically Vector or Matrix)

## Types 

The typical field structure for methods in `OnlineStats`:

```
type OnlineStatistic
	estimate         # current estimate
	sufficient_stat  # values needed to update estimate
	n                # Number of observations used
end
```



## Thank you
I often find myself looking through the source code of the following packages.  

- [StreamStats](https://github.com/johnmyleswhite/StreamStats.jl)
- [GLM](https://github.com/JuliaStats/GLM.jl)  
- [Distributions](https://github.com/JuliaStats/Distributions.jl)  
- [DataFrames](https://github.com/JuliaStats/DataFrames.jl)
