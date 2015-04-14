
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
elapsed time: 1.631410394 seconds (505490288 bytes allocated, 48.35%
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
elapsed time: 1.90387225 seconds (493971312 bytes allocated, 39.66% gc
time)
````





### Check estimates
````julia
julia> state(obj_sgd)
12x2 Array{Any,2}:
 :q10      0.0990596
 :q20      0.200544 
 :q30      0.299496 
 :q40      0.398427 
 :q50      0.498748 
 :q60      0.601011 
 :q70      0.70137  
 :q80      0.804388 
 :q90      0.901381 
 :r        0.6      
 :n        1.0e6    
 :nb   10000.0      

julia> state(obj_mm)
12x2 Array{Any,2}:
 :q10      0.0993548
 :q20      0.199955 
 :q30      0.29972  
 :q40      0.400059 
 :q50      0.500134 
 :q60      0.599997 
 :q70      0.700815 
 :q80      0.80109  
 :q90      0.900361 
 :r        0.6      
 :n        1.0e6    
 :nb   10000.0      

julia> 
# SGD: Maximum difference from truth
maxabs(obj_sgd.est - [1:9]/10)
0.004387738288382681

julia> 
# MM: Maximum difference from truth
maxabs(obj_mm.est - [1:9]/10)
0.0010899547613755223

````





### Check Traceplots
````julia
results_sgd_melt = melt(results_sgd, 10:12)
results_mm_melt = melt(results_mm, 10:12)

plot(results_sgd_melt, x="n", y="value", color="variable", yintercept=[1:9]/10, Geom.line, Geom.hline)
plot(results_mm_melt, x="n", y="value", color="variable", yintercept=[1:9]/10, Geom.line, Geom.hline)
````


![](figures/quantilecompare_7_1.png)
![](figures/quantilecompare_7_2.png)



