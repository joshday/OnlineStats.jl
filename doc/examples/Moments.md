
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
 :m1            0.00142514
 :m2            1.00867   
 :m3            0.0615038 
 :m4            2.97578   
 :skewness      0.0607123 
 :kurtosis     -0.0751685 
 :n         10100.0       
 :nb            1.0       

````


