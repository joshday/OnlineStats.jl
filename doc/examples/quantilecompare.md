
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
elapsed time: 1.858553807 seconds (505490288 bytes allocated, 49.01%
gc time)
````




````julia
srand(123)
@time for i = 1:9999
    update!(obj_mm, rand(100))
    make_df!(results_mm, obj_mm)
end
````


````julia
elapsed time: 2.315507547 seconds (493971328 bytes allocated, 38.97%
gc time)
````





### Check estimates
````julia
julia> state(obj_sgd)
12x2 Array{Any,2}:
 :q10      0.0990616
 :q20      0.200537 
 :q30      0.299516 
 :q40      0.398425 
 :q50      0.498746 
 :q60      0.60101  
 :q70      0.701376 
 :q80      0.804393 
 :q90      0.901374 
 :r        0.6      
 :n        1.0e6    
 :nb   10000.0      

julia> state(obj_mm)
12x2 Array{Any,2}:
 :q10      0.0993261
 :q20      0.199842 
 :q30      0.30036  
 :q40      0.399957 
 :q50      0.500336 
 :q60      0.600581 
 :q70      0.700774 
 :q80      0.801108 
 :q90      0.90034  
 :r        0.6      
 :n        1.0e6    
 :nb   10000.0      

julia> 
# SGD: Maximum difference from truth
maxabs(obj_sgd.est - [1:9]/10)
0.004393047320199406

julia> 
# MM: Maximum difference from truth
maxabs(obj_mm.est - [1:9]/10)
0.001107627410528056

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



