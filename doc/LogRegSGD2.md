
# LogRegSGD2


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

o = LogRegSGD2(X, y, StochasticWeighting(.6))
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
 -0.503038  
 -0.405131  
 -0.298531  
 -0.203155  
 -0.102307  
  0.00581201
  0.100584  
  0.198295  
  0.301771  
  0.397414  
  0.501976  

julia> df_unpacked = unpack_vectors(df)
110000x3 DataFrame
| Row    | β           | nobs    | vectorindex |
|--------|-------------|---------|-------------|
| 1      | -0.149712   | 100     | β1          |
| 2      | -0.0721956  | 100     | β2          |
| 3      | -0.0684345  | 100     | β3          |
| 4      | -0.122121   | 100     | β4          |
| 5      | -0.00361269 | 100     | β5          |
| 6      | 0.0442493   | 100     | β6          |
| 7      | 0.0154255   | 100     | β7          |
| 8      | 0.115325    | 100     | β8          |
⋮
| 109992 | -0.298531   | 1000000 | β3          |
| 109993 | -0.203155   | 1000000 | β4          |
| 109994 | -0.102307   | 1000000 | β5          |
| 109995 | 0.00581201  | 1000000 | β6          |
| 109996 | 0.100584    | 1000000 | β7          |
| 109997 | 0.198295    | 1000000 | β8          |
| 109998 | 0.301771    | 1000000 | β9          |
| 109999 | 0.397414    | 1000000 | β10         |
| 110000 | 0.501976    | 1000000 | β11         |

julia> plot(df_unpacked, x = :nobs, y = :β, color = :vectorindex, Geom.line,
            yintercept = β, Geom.hline(color = "black"),
            Scale.y_continuous(minvalue=-.6, maxvalue=.6))

````


![](figures/LogRegSGD2_5_1.png)



