
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
6x2 Array{Any,2}:
 :mean      9.99421 
 :var      24.9917  
 :max      34.4151  
 :min     -16.5679  
 :n         1.0001e6
 :nb    10001.0     

````


