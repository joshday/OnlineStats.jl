
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
 :m1            0.0191281
 :m2            1.01418  
 :m3            0.0415386
 :m4            3.12974  
 :skewness      0.0406704
 :kurtosis      0.0428289
 :n         10100.0      
 :nb            1.0      

````


