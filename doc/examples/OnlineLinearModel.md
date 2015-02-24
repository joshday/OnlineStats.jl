
# OnlineLinearModel


````julia
using OnlineStats
using Gadfly
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
x1   -0.0157407 0.0329041 -0.478381   0.6324
x2   0.00199181 0.0329085 0.0605256   0.9517
x3     0.995074 0.0328727   30.2705   <1e-99
x4      1.07228 0.0328982   32.5939   <1e-99
x5      1.94522 0.0329095   59.1082   <1e-99
x6      1.98987 0.0328987   60.4846   <1e-99
x7      3.03812   0.03287   92.4284   <1e-99
x8      2.96749 0.0329164   90.1524   <1e-99
x9      4.04042 0.0329065   122.785   <1e-99
x10     3.98263 0.0328832   121.115   <1e-99


julia> mse(fit)  # Estimate of MSE
99.91038964611522

julia> maximum(abs(beta - coef(fit)))  # Max Absolute Error
0.07228069429254846

````


