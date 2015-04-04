
# LogRegMM


````julia
using OnlineStats
using Distributions, StatsBase, Gadfly, DataFrames
````





### Function to help generate data
````julia
logitexp(x) = 1 / (1 + exp(-x))
@vectorize_1arg Real logitexp
````





### Create model with the first batch
````julia
β = ([1:10] - 10/2) / 10
xs = randn(100, 10)
ys = vec(logitexp(xs * β))
for i in 1:length(ys)
    ys[i] = rand(Distributions.Bernoulli(ys[i]))
end

obj = OnlineStats.LogRegMM(xs, ys, r=.7)
df = OnlineStats.make_df(obj) # Save estimates to DataFrame
````





### Update model with many batches
````julia
for i in 1:999
    xs = randn(100, 10)
    ys = vec(logitexp(xs * β))
    for i in 1:length(ys)
        ys[i] = rand(Distributions.Bernoulli(ys[i]))
    end

    OnlineStats.update!(obj, xs, ys)
    OnlineStats.make_df!(df, obj)  # append results to DataFrame
end
````





### Check fit
````julia
julia> coef(obj)
11-element Array{Float64,1}:
  0.00580482
 -0.387341  
 -0.286656  
 -0.204913  
 -0.0997229 
 -0.00526056
  0.102379  
  0.19715   
  0.306173  
  0.396343  
  0.513002  

julia> df_melt = melt(df, 12:13)
11000x4 DataFrame
| Row   | variable | value     | n        | nb     |
|-------|----------|-----------|----------|--------|
| 1     | β0       | 0.295652  | 100.0    | 1.0    |
| 2     | β0       | 0.122401  | 200.0    | 2.0    |
| 3     | β0       | 0.118033  | 300.0    | 3.0    |
| 4     | β0       | 0.104443  | 400.0    | 4.0    |
| 5     | β0       | 0.0974549 | 500.0    | 5.0    |
| 6     | β0       | 0.0916349 | 600.0    | 6.0    |
| 7     | β0       | 0.0962349 | 700.0    | 7.0    |
| 8     | β0       | 0.0921761 | 800.0    | 8.0    |
⋮
| 10992 | β10      | 0.512666  | 99200.0  | 992.0  |
| 10993 | β10      | 0.513014  | 99300.0  | 993.0  |
| 10994 | β10      | 0.513229  | 99400.0  | 994.0  |
| 10995 | β10      | 0.513326  | 99500.0  | 995.0  |
| 10996 | β10      | 0.513514  | 99600.0  | 996.0  |
| 10997 | β10      | 0.513362  | 99700.0  | 997.0  |
| 10998 | β10      | 0.513645  | 99800.0  | 998.0  |
| 10999 | β10      | 0.51315   | 99900.0  | 999.0  |
| 11000 | β10      | 0.513002  | 100000.0 | 1000.0 |

julia> Gadfly.plot(df_melt, x=:n, y=:value, color=:variable, Gadfly.Geom.line,
            yintercept=β, Gadfly.Geom.hline,
            Gadfly.Scale.y_continuous(minvalue=-1, maxvalue=1))

````


![](figures/LogRegMM_5_1.png)



