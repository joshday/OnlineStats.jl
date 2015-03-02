
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
11x2 Array{Any,2}:
 :q10      0.0998468
 :q20      0.200027 
 :q30      0.299924 
 :q40      0.399661 
 :q50      0.500237 
 :q60      0.600467 
 :q70      0.700304 
 :q80      0.799679 
 :q90      0.899978 
 :n        1.0001e6 
 :nb   10001.0      

julia> 
# Maximum difference from truth
maxabs(obj.est - [1:9]/10)
0.0004668304727072359

````


