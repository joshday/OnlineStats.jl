
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
 :min       1.92557e-5
 :q25       0.254488  
 :q50       0.503957  
 :q75       0.748034  
 :max       0.999993  
 :n    100100.0       
 :nb     1001.0       

julia> plot(obj)

````


![](figures/FiveNumberSummary_4_1.png)



