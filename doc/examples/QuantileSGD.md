
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
 :q10      0.100265
 :q20      0.201974
 :q30      0.299525
 :q40      0.400453
 :q50      0.501296
 :q60      0.599013
 :q70      0.699524
 :q80      0.798136
 :q90      0.898945
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maximum(abs(obj.est - [1:9]/10))
0.001973625653733463

````


