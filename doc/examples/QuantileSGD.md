
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
 :q10      0.094473
 :q20      0.192832
 :q30      0.291982
 :q40      0.394145
 :q50      0.493914
 :q60      0.592954
 :q70      0.693639
 :q80      0.796256
 :q90      0.898344
 :n        1.0001e6
 :nb   10001.0     

julia> 
# Maximum difference from truth
maximum(abs(obj.est - [1:9]/10))
0.008018284921527619

````


