# OnlineStats

Online algorithms for statistics.  The driving function in this package is  

```update!(obj, newdata)```  
- `obj`: subtype of `OnlineStat`  
- `newdata`: new observations

Data is updated in **batches**


## Types 
Each type defined in OnlineStats contains the fields  

- `<<estimate>>`: Vector of saved estimates
- `n`: number of observations used (display with `n_obs(obj)`)
- `nb`: number of batches used (display with `n_batches(obj)`)

Other fields will be used to store sufficient statistics for online updates.

## Documentation
TODO: Will be hosted on RTD

 
## Thank you
A big thank you to the following packages.  I often found myself digging through their source code.

- [GLM](https://github.com/JuliaStats/GLM.jl)  
- [Distributions](https://github.com/JuliaStats/Distributions.jl)  
- [DataFrames](https://github.com/JuliaStats/DataFrames.jl)