
# QuantileMM


````julia
using OnlineStats, DataFrames
````





### Create model with the first batch
````julia
o = QuantileMM(rand(100), τ=[.1:.2:.9])
````





### Update model with many batches
````julia
for i = 1:10000
    update!(o, rand(100))
end
````





### Check estimates
Since true distribution is Uniform(0, 1), true quantiles equal τ.

````julia
julia> DataFrame(o)
1x3 DataFrame
| Row | quantiles                                       |
|-----|-------------------------------------------------|
| 1   | [0.0931725,0.290068,0.495264,0.699803,0.900968] |

| Row | τ                     | nobs    |
|-----|-----------------------|---------|
| 1   | [0.1,0.3,0.5,0.7,0.9] | 1000100 |

````




