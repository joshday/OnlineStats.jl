
# OnlineFitBeta


````julia
using OnlineStats
using Distributions
using Gadfly
````





### Create estimate with first batch
````julia
x = rand(Beta(3, 5), 100)
obj = onlinefit(Beta, x)
````


````julia
Beta(α=3.3226992896214265, β=5.688928186485474)
````





### Update model with many batches
````julia
for i = 1:10000
    x = rand(Beta(3, 5), 100)
    update!(obj, x)
end
````





### Check fit
````julia
julia> state(obj)
4x2 Array{Any,2}:
 :α       3.00339 
 :β       5.00886 
 :n       1.0001e6
 :nb  10001.0     

````




