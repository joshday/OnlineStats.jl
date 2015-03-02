
# Moments


````julia
using OnlineStats
````





### Create object with the first batch
````julia
obj = Moments(rand(100))
````





### Update estimates with many batches
````julia
for i = 1:10000
    update!(obj, rand(100))
end
````





### Check estimates
Truth:

| Estimate | value
|----------|--------
| Mean     | 0.5
| Var      | 0.08333...
| Skewness | 0
| Kurtosis | -1.2

````julia
julia> state(obj)
5x2 Array{Any,2}:
 :mean       0.49986   
 :var        0.0833943 
 :skewness   0.00139893
 :kurtosis  -1.20101   
 :n          1.0001e6  

````


