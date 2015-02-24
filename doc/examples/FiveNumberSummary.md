
# FiveNumberSummary


````julia
using OnlineStats
using Gadfly
````





### Create 5-number summary with the first batch
````julia
obj = FiveNumberSummary(rand(100))
````





### Update model with many batches
````julia
for i = 1:1000
    update!(obj, rand(100))
end
````





### Check estimate
````julia
julia> state(obj)
7x2 Array{Any,2}:
 :min       1.37266e-5
 :q25       0.252858  
 :q50       0.50411   
 :q75       0.754948  
 :max       0.999995  
 :n    100100.0       
 :nb     1001.0       

julia> plot(obj)

````


![](figures/FiveNumberSummary_4_1.png)



