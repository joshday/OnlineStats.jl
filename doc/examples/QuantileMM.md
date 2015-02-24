
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
 :q10      0.100108
 :q20      0.19926 
 :q30      0.300683
 :q40      0.400052
 :q50      0.499791
 :q60      0.599905
 :q70      0.70004 
 :q80      0.800173
 :q90      0.900146
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maximum(abs(obj.est - [1:9]/10))
0.0007400872714883322

````


