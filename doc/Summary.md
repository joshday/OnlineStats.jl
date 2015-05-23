
# Summary


````julia
using OnlineStats, DataFrames
````





### Create fit with the first batch
````julia
o = Summary(randn(100))
````





### Update model with many batches
````julia
for i = 1:10000
    update!(o, randn(100))
end
````





### Check summary statistics
````julia
julia> DataFrame(o)
1x5 DataFrame
| Row | μ            | σ²       | max     | min      | nobs    |
|-----|--------------|----------|---------|----------|---------|
| 1   | -0.000133912 | 0.999889 | 4.72487 | -4.82758 | 1000100 |

````




