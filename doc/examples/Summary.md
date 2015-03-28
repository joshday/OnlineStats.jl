
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
 :mean   10.0012  
 :var    24.953   
 :max    33.781   
 :min   -14.8106  
 :n       1.0001e6

````


