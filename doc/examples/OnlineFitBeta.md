
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





### Update model with many batches
````julia
for i = 1:1000
    x = rand(Beta(3, 5), 100)
    update!(obj, x)
end
````





### Check fit
````julia
julia> state(obj)
2x2 Array{Any,2}:
 :α  2.96816
 :β  4.95153

````


