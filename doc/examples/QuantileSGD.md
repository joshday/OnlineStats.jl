
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
 :q10      0.100474
 :q20      0.200612
 :q30      0.300065
 :q40      0.399439
 :q50      0.500056
 :q60      0.598427
 :q70      0.698992
 :q80      0.79906 
 :q90      0.901416
 :r        0.6     
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maxabs(obj.est - [1:9]/10)
0.001572796512552932

````


