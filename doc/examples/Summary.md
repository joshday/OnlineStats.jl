
# Summary


````julia
using OnlineStats, DataFrames
````





### Create fit with the first batch
````julia
obj = Summary(randn(100))
````





### Update model with many batches
````julia
for i = 1:10000
    update!(obj, randn(100))
end
````





### Check summary statistics

````julia
julia> DataFrame(obj)
1x5 DataFrame
| Row | μ            | σ²       | max     | min      | nobs    |
|-----|--------------|----------|---------|----------|---------|
| 1   | -0.000174127 | 0.998897 | 4.62863 | -4.51318 | 1000100 |

````


