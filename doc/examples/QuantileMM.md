
# QuantileMM


````julia
using OnlineStats
````





### Create model with the first batch
````julia
obj = QuantileMM(rand(100), τ=[1:9]/10)
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
12x2 Array{Any,2}:
 :q10      0.0994721
 :q20      0.199461 
 :q30      0.300334 
 :q40      0.400055 
 :q50      0.499882 
 :q60      0.599753 
 :q70      0.700228 
 :q80      0.800889 
 :q90      0.900081 
 :r        0.6      
 :n        1.0001e6 
 :nb   10001.0      

julia> 
# Maximum difference from truth
maxabs(obj.est - [1:9]/10)
0.0008893334418610399

````


