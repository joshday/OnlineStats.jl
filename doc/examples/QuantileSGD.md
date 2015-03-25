
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
 :q10      0.100565
 :q20      0.20063 
 :q30      0.298599
 :q40      0.398039
 :q50      0.49745 
 :q60      0.599545
 :q70      0.701767
 :q80      0.80254 
 :q90      0.902667
 :r        0.6     
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maxabs(obj.est - [1:9]/10)
0.002667263724625002

````


