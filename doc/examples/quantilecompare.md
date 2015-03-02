
# Compare: `QuantileSGD` vs. `QuantileMM`


````julia
using OnlineStats
using Gadfly
using DataFrames
````





### Create model with the first batch
````julia
obj_sgd = QuantileSGD(rand(100), τ=[1:9]/10, r=.6)
obj_mm = QuantileMM(rand(100), τ=[1:9]/10, r=.6)
````





### Save results for trace plots

`make_df` constructs a `DataFrame` from any subtype of `OnlineStat`.

````julia
results_sgd = make_df(obj_sgd)
results_mm = make_df(obj_mm)
````





### Update model with many batches

`make_df!(df, obj)` adds a row to `df::DataFrame` using the current state of `obj<:OnlineStat`.  This is useful for generating trace plots.

````julia
srand(123)
@time for i = 1:9999
    update!(obj_sgd, rand(100))
    make_df!(results_sgd, obj_sgd)
end
````


````julia
elapsed time: 1.50462606 seconds (483848380 bytes allocated, 43.77% gc
time)
````




````julia
srand(123)
@time for i = 1:9999
    update!(obj_mm, rand(100))
    make_df!(results_mm, obj_mm)
end
````


````julia
elapsed time: 1.716931792 seconds (480513996 bytes allocated, 33.67%
gc time)
````





### Check estimates
````julia
julia> state(obj_sgd)
11x2 Array{Any,2}:
 :q10      0.0990626
 :q20      0.200547 
 :q30      0.299526 
 :q40      0.398426 
 :q50      0.498745 
 :q60      0.601001 
 :q70      0.701346 
 :q80      0.804389 
 :q90      0.901383 
 :n        1.0e6    
 :nb   10000.0      

julia> state(obj_mm)
11x2 Array{Any,2}:
 :q10      0.0993301
 :q20      0.200007 
 :q30      0.299797 
 :q40      0.400161 
 :q50      0.500338 
 :q60      0.600613 
 :q70      0.700748 
 :q80      0.801023 
 :q90      0.900373 
 :n        1.0e6    
 :nb   10000.0      

julia> 
# SGD: Maximum difference from truth
maxabs(obj_sgd.est - [1:9]/10)
0.004388525552945999

julia> 
# MM: Maximum difference from truth
maxabs(obj_mm.est - [1:9]/10)
0.0010229396671924684

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



