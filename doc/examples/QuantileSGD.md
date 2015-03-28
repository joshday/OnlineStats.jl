
# QuantileSGD


````julia
using OnlineStats
````





### Create model with the first batch
````julia
obj = QuantileSGD(rand(100), τ=[1:9]/10)
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
 :q10      0.100279
 :q20      0.201024
 :q30      0.299273
 :q40      0.399322
 :q50      0.501994
 :q60      0.60139 
 :q70      0.701933
 :q80      0.801645
 :q90      0.900463
 :r        0.6     
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maxabs(obj.est - [1:9]/10)
0.0019942025912206285

````


