
# LogRegSGD


````julia
using OnlineStats, Distributions, StatsBase, Gadfly, DataFrames
````





### Function to help generate data
````julia
inverselogit(x) = 1 / (1 + exp(-x))
@vectorize_1arg Real inverselogit
````





### Create model with the first batch
````julia
β = [-.5:.1:.5]
X = [ones(100) randn(100, 10)]
y = int(inverselogit(X * β) .> rand(100))

o = LogRegSGD(X, y, StochasticWeighting(1.0))
df = DataFrame(o)  # Create DataFrame
````





### Update model with many batches
````julia
for i in 1:9999
    X = [ones(100) randn(100, 10)]
    y = int(inverselogit(X * β) .> rand(100))

    updatebatch!(o, X, y)
    push!(df, o)  # append results to DataFrame
end
````





### Check fit
````julia
julia> coef(o)
11-element Array{Float64,1}:
 -0.501147  
 -0.394858  
 -0.300038  
 -0.191201  
 -0.102111  
 -0.00023253
  0.103775  
  0.193361  
  0.297432  
  0.393264  
  0.501527  

julia> df_unpacked = unpack_vectors(df)
110000x3 DataFrame
| Row    | β           | nobs    | vectorindex |
|--------|-------------|---------|-------------|
| 1      | -9.0        | 100     | β1          |
| 2      | -15.3168    | 100     | β2          |
| 3      | -1.87193    | 100     | β3          |
| 4      | -11.0531    | 100     | β4          |
| 5      | -1.91965    | 100     | β5          |
| 6      | -0.690715   | 100     | β6          |
| 7      | 1.24558     | 100     | β7          |
| 8      | 5.45841     | 100     | β8          |
⋮
| 109992 | -0.300038   | 1000000 | β3          |
| 109993 | -0.191201   | 1000000 | β4          |
| 109994 | -0.102111   | 1000000 | β5          |
| 109995 | -0.00023253 | 1000000 | β6          |
| 109996 | 0.103775    | 1000000 | β7          |
| 109997 | 0.193361    | 1000000 | β8          |
| 109998 | 0.297432    | 1000000 | β9          |
| 109999 | 0.393264    | 1000000 | β10         |
| 110000 | 0.501527    | 1000000 | β11         |

julia> plot(df_unpacked, x = :nobs, y = :β, color = :vectorindex, Geom.line,
            yintercept = β, Geom.hline(color = "black"),
            Scale.y_continuous(minvalue=-.6, maxvalue=.6))

````


![](figures/LogRegSGD_5_1.png)



