
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
elapsed time: 0.767898999 seconds (395991840 bytes allocated, 52.16%
gc time)
````




````julia
srand(123)
@time for i = 1:10000
    update!(obj_mm, rand(100))
end
````


````julia
elapsed time: 0.820042405 seconds (395991856 bytes allocated, 55.52%
gc time)
````





### Check estimates
````julia
julia> state(obj_sgd)
11x2 Array{Any,2}:
 :q10      0.0997124
 :q20      0.202428 
 :q30      0.301659 
 :q40      0.400707 
 :q50      0.500434 
 :q60      0.602456 
 :q70      0.702155 
 :q80      0.805904 
 :q90      0.901185 
 :n        1.0001e6 
 :nb   10001.0      

julia> state(obj_mm)
11x2 Array{Any,2}:
 :q10      0.0997899
 :q20      0.202405 
 :q30      0.301618 
 :q40      0.400689 
 :q50      0.500449 
 :q60      0.602455 
 :q70      0.702115 
 :q80      0.805881 
 :q90      0.901183 
 :n        1.0001e6 
 :nb   10001.0      

julia> 
# SGD: Maximum difference from truth
maximum(abs(obj_sgd.est - [1:9]/10))
0.005903944080854484

julia> 
# MM: Maximum difference from truth
maximum(abs(obj_mm.est - [1:9]/10))
0.005880714407892174

````


