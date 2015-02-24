
# Moments


````julia
using OnlineStats
````





### Create object with the first batch
````julia
obj = Moments(randn(100))
````





### Update estimates with many batches
````julia
for i = 1:10000
    update!(obj, randn(100))
end
````





### Check estimates
````julia
julia> state(obj)
8x2 Array{Any,2}:
 :m1            0.00733219 
 :m2            0.974091   
 :m3           -0.0236144  
 :m4            2.84702    
 :skewness     -0.0245628  
 :kurtosis      0.000482356
 :n         10100.0        
 :nb            1.0        

````


