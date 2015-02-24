
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
 :q10      0.101622
 :q20      0.203628
 :q30      0.303764
 :q40      0.404189
 :q50      0.499984
 :q60      0.600565
 :q70      0.69845 
 :q80      0.796452
 :q90      0.898976
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maximum(abs(obj.est - [1:9]/10))
0.004188505413270982

````


