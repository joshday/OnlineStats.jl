
# QuantileMM


````julia
using OnlineStats
````





### Create model with the first batch
````julia
obj = QuantileMM(rand(100), tau=[1:9]/10)
````





### Update model with many batches
````julia
for i = 1:10000
    update!(obj, rand(100))
end
````





### Check estimates
````julia
julia> state(obj)
11x2 Array{Any,2}:
 :q10      0.10152 
 :q20      0.199526
 :q30      0.299651
 :q40      0.401378
 :q50      0.500413
 :q60      0.600747
 :q70      0.699568
 :q80      0.800909
 :q90      0.900548
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maximum(abs(obj.est - [1:9]/10))
0.0015199772358479996

````


