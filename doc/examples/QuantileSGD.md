
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
 :q10      0.0962912
 :q20      0.194722 
 :q30      0.295628 
 :q40      0.397564 
 :q50      0.498474 
 :q60      0.599203 
 :q70      0.697225 
 :q80      0.797975 
 :q90      0.898652 
 :r        0.6      
 :n        1.0001e6 
 :nb   10001.0      

julia> 
# Maximum difference from truth
maxabs(obj.est - [1:9]/10)
0.00527756989074743

````


