
# Compare: `QuantileSGD` vs. `QuantileMM`


````julia
using OnlineStats
using Gadfly
using DataFrames
````





### Create model with the first batch
````julia
obj_sgd = QuantileSGD(rand(100), tau=[1:9]/10, r=.6)
obj_mm = QuantileSGD(rand(100), tau=[1:9]/10, r=.6)
````





### Save results for trace plots
````julia
results_sgd = make_df(obj_sgd)
results_mm = make_df(obj_mm)
````





### Update model with many batches
````julia
srand(123)
@time for i = 1:9999
    update!(obj_sgd, rand(100))
    make_df!(obj_sgd, results_sgd)
end
````


````julia
elapsed time: 1.529481538 seconds (491948552 bytes allocated, 47.67%
gc time)
````




````julia
srand(123)
@time for i = 1:9999
    update!(obj_mm, rand(100))
    make_df!(obj_mm, results_mm)
end
````


````julia
elapsed time: 1.59696385 seconds (491948424 bytes allocated, 50.39% gc
time)
````





### Check estimates
````julia
julia> state(obj_sgd)
11x2 Array{Any,2}:
 :q10      0.0990498
 :q20      0.200525 
 :q30      0.299503 
 :q40      0.398423 
 :q50      0.498745 
 :q60      0.60099  
 :q70      0.701338 
 :q80      0.804398 
 :q90      0.901368 
 :n        1.0e6    
 :nb   10000.0      

julia> state(obj_mm)
11x2 Array{Any,2}:
 :q10      0.0990599
 :q20      0.200526 
 :q30      0.299523 
 :q40      0.398399 
 :q50      0.498746 
 :q60      0.601001 
 :q70      0.701351 
 :q80      0.80438  
 :q90      0.901394 
 :n        1.0e6    
 :nb   10000.0      

julia> 
# SGD: Maximum difference from truth
maximum(abs(obj_sgd.est - [1:9]/10))
0.004397544718487301

julia> 
# MM: Maximum difference from truth
maximum(abs(obj_mm.est - [1:9]/10))
0.004380254215353374

````





### Check Traceplots
````julia
results_sgd = melt(results_sgd, 10:11)
results_mm = melt(results_mm, 10:11)

plot(results_sgd, x="n", y="value", color="variable", yintercept=[1:9]/10, Geom.line, Geom.hline)
plot(results_mm, x="n", y="value", color="variable", yintercept=[1:9]/10, Geom.line, Geom.hline)
````


![](figures/quantilecompare_7_1.png)
![](figures/quantilecompare_7_2.png)



