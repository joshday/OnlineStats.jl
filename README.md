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

- `estimate`: Current estimate
- `sufficient_stats`:  Values needed to update estimate
- `n`: number of observations (display with `n_obs(obj)`)



## Thank you
I often find myself looking through the source code of the following packages.  

- [StreamStats](https://github.com/johnmyleswhite/StreamStats.jl)
- [GLM](https://github.com/JuliaStats/GLM.jl)  
- [Distributions](https://github.com/JuliaStats/Distributions.jl)  
- [DataFrames](https://github.com/JuliaStats/DataFrames.jl)
