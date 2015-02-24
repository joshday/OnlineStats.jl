
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
 :q10      0.0999548
 :q20      0.200121 
 :q30      0.299276 
 :q40      0.39845  
 :q50      0.499604 
 :q60      0.599065 
 :q70      0.69917  
 :q80      0.800059 
 :q90      0.899787 
 :n        1.0001e6 
 :nb   10001.0      

julia> 
# Maximum difference from truth
maximum(abs2(obj.est - [1:9]/10))
2.4030273115773853e-6

````


