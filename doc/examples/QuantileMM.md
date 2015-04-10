
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
 :q10      0.100179
 :q20      0.200192
 :q30      0.301524
 :q40      0.401901
 :q50      0.501591
 :q60      0.600928
 :q70      0.70101 
 :q80      0.800118
 :q90      0.900379
 :r        0.6     
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maxabs(obj.est - [1:9]/10)
0.0019007360526936967

````


