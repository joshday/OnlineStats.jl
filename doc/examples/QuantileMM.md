
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
 :q10      0.0995787
 :q20      0.199767 
 :q30      0.300138 
 :q40      0.40012  
 :q50      0.499149 
 :q60      0.599607 
 :q70      0.699907 
 :q80      0.799872 
 :q90      0.899601 
 :n        1.0001e6 
 :nb   10001.0      

julia> 
# Maximum difference from truth
maximum(abs(obj.est - [1:9]/10))
0.0008511725611484722

````


