[![Build Status](https://travis-ci.org/joshday/OnlineStats.jl.svg)](https://travis-ci.org/joshday/OnlineStats.jl)

# OnlineStats

Online algorithms for statistics.  The driving function in this package is  

```update!(obj, newdata)```  
- `obj`: subtype of `OnlineStat`  
- `newdata`: new observations (typically Vector or Matrix)

Data is updated in **batches**


## Types 

See implementation progress in [src/README.md](src/README.md)

Each type defined in OnlineStats contains the fields  

- `<<estimate>>`: Vector of saved estimates
- `n`: number of observations used (display with `n_obs(obj)`)
- `nb`: number of batches used (display with `n_batches(obj)`)

Other fields will be used to store sufficient statistics for online updates.



## Documentation
See `doc/` and `doc/examples`

 
## Thank you
I often find myself looking through the source code of the following packages.  

- [StreamStats](https://github.com/johnmyleswhite/StreamStats.jl)
- [GLM](https://github.com/JuliaStats/GLM.jl)  
- [Distributions](https://github.com/JuliaStats/Distributions.jl)  
- [DataFrames](https://github.com/JuliaStats/DataFrames.jl)
