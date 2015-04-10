
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
 :mean   10.0011  
 :var    25.0209  
 :max    35.0562  
 :min   -14.1815  
 :n       1.0001e6

````


