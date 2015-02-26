
# QuantileSGD


````julia
using OnlineStats
````





### Create model with the first batch
````julia
obj = QuantileSGD(rand(100), tau=[1:9]/10)
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
 :q10      0.100721
 :q20      0.202149
 :q30      0.305032
 :q40      0.400771
 :q50      0.496892
 :q60      0.600801
 :q70      0.701899
 :q80      0.799481
 :q90      0.899352
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maximum(abs(obj.est - [1:9]/10))
0.005032414231550819

````


