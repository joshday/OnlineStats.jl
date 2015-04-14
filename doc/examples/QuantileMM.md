
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
 :q10      0.099912
 :q20      0.19965 
 :q30      0.300175
 :q40      0.400868
 :q50      0.500876
 :q60      0.600521
 :q70      0.701007
 :q80      0.801241
 :q90      0.900913
 :r        0.6     
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maxabs(obj.est - [1:9]/10)
0.0012406972190104337

````


