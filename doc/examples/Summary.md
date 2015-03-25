
# Summary


````julia
using OnlineStats
using Distributions
````





### Create fit with the first batch
````julia
x = rand(Normal(10, 5), 100)
obj = Summary(x)
````





### Update model with many batches
````julia
for i = 1:10000
    x = rand(Normal(10, 5), 100)
    update!(obj, x)
end
````





### Check summary statistics
````julia
julia> state(obj)
5x2 Array{Any,2}:
 :mean    9.99688 
 :var    25.0328  
 :max    33.7578  
 :min   -13.7578  
 :n       1.0001e6

````


