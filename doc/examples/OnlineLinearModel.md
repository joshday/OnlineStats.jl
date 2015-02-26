
# OnlineLinearModel


````julia
using OnlineStats
````





### Make true beta
````julia
p = 10
beta = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4]
````





### Create model with the first batch
````julia
x = rand(100, p)
y = x * beta + 10*randn(100)

fit = OnlineLinearModel(x, y)
````





### Update model with many batches
````julia
for i = 1:10000
    x = rand(100, p)
    y = x * beta + 10*randn(100)
    update!(fit, x, y)
end
````





### Check fit
````julia
julia> coeftable(fit)  # CoefTable
       Estimate Std.Error   t value Pr(>|t|)
x1   -0.0320876 0.0329311 -0.974385   0.3299
x2   -0.0179435 0.0329339 -0.544833   0.5859
x3      1.02063 0.0329263   30.9974   <1e-99
x4      1.00637 0.0329703   30.5234   <1e-99
x5      2.02474 0.0329418   61.4641   <1e-99
x6      1.95655 0.0329206   59.4324   <1e-99
x7      2.97139 0.0329094   90.2899   <1e-99
x8      2.99421 0.0329278   90.9326   <1e-99
x9      4.04416 0.0329563   122.713   <1e-99
x10     4.01522 0.0329479   121.866   <1e-99


julia> mse(fit)  # Estimate of MSE
100.06898543140069

julia> maximum(abs(beta - coef(fit)))  # Max Absolute Error
0.044161113092718196

````


