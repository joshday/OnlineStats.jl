
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
 :q10      0.0989954
 :q20      0.196615 
 :q30      0.29804  
 :q40      0.399943 
 :q50      0.500232 
 :q60      0.599509 
 :q70      0.702286 
 :q80      0.800235 
 :q90      0.896978 
 :n        1.0001e6 
 :nb   10001.0      

julia> 
# Maximum difference from truth
maximum(abs(obj.est - [1:9]/10))
0.0033854883678114955

````


