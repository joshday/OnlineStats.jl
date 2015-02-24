
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
 :q10      0.102136
 :q20      0.201825
 :q30      0.298981
 :q40      0.400641
 :q50      0.500327
 :q60      0.596328
 :q70      0.695937
 :q80      0.797149
 :q90      0.89875 
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maximum(abs2(obj.est - [1:9]/10))
1.6511772293914375e-5

````


