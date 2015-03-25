
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
 :q10      0.0996619
 :q20      0.199277 
 :q30      0.299064 
 :q40      0.398405 
 :q50      0.498702 
 :q60      0.599146 
 :q70      0.699238 
 :q80      0.79994  
 :q90      0.899537 
 :r        0.6      
 :n        1.0001e6 
 :nb   10001.0      

julia> 
# Maximum difference from truth
maxabs(obj.est - [1:9]/10)
0.0015945666888059762

````


