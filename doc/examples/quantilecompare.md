
# Compare: `QuantileSGD` vs. `QuantileMM`


````julia
using OnlineStats
````





### Create model with the first batch
````julia
obj_sgd = QuantileSGD(rand(100), tau=[1:9]/10)
obj_mm = QuantileSGD(rand(100), tau=[1:9]/10)
````





### Update model with many batches
````julia
srand(123)
@time for i = 1:10000
    update!(obj_sgd, rand(100))
end
````


````julia
elapsed time: 0.879212313 seconds (395991952 bytes allocated, 58.64%
gc time)
````




````julia
srand(123)
@time for i = 1:10000
    update!(obj_mm, rand(100))
end
````


````julia
elapsed time: 0.795719686 seconds (395991872 bytes allocated, 56.04%
gc time)
````





### Check estimates
````julia
julia> state(obj_sgd)
11x2 Array{Any,2}:
 :q10      0.0997432
 :q20      0.202445 
 :q30      0.301663 
 :q40      0.400746 
 :q50      0.500426 
 :q60      0.602441 
 :q70      0.702176 
 :q80      0.805875 
 :q90      0.901161 
 :n        1.0001e6 
 :nb   10001.0      

julia> state(obj_mm)
11x2 Array{Any,2}:
 :q10      0.0997022
 :q20      0.202442 
 :q30      0.301649 
 :q40      0.400751 
 :q50      0.500436 
 :q60      0.602459 
 :q70      0.702117 
 :q80      0.805878 
 :q90      0.901155 
 :n        1.0001e6 
 :nb   10001.0      

julia> 
# SGD: Maximum difference from truth
maximum(abs(obj_sgd.est - [1:9]/10))
0.005875444661822438

julia> 
# MM: Maximum difference from truth
maximum(abs(obj_mm.est - [1:9]/10))
0.005877915041495152

````


