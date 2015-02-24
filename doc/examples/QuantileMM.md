
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
 :q10      0.099843
 :q20      0.199351
 :q30      0.299863
 :q40      0.400464
 :q50      0.499325
 :q60      0.599992
 :q70      0.699962
 :q80      0.799143
 :q90      0.899677
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maximum(abs(obj.est - [1:9]/10))
0.0008574349947991777

````


