
# QuantileMM


````julia
using OnlineStats
````





### Create model with the first batch
````julia
obj = QuantileMM(rand(100), tau=[1:9]/10)
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
 :q10      0.100679
 :q20      0.20094 
 :q30      0.299862
 :q40      0.40104 
 :q50      0.501455
 :q60      0.600785
 :q70      0.701706
 :q80      0.801594
 :q90      0.901411
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maximum(abs(obj.est - [1:9]/10))
0.0017055327127191156

````


