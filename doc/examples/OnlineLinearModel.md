
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
y = x * beta + randn(100)

fit = OnlineLinearModel(x, y)
````





### Update model with many batches
````julia
for i = 1:1000
    x = rand(100, p)
    y = x * beta + randn(100)
    update!(fit, x, y)
end
````





### Check fit
````julia
julia> coeftable(fit)
        Estimate Std.Error   t value Pr(>|t|)
x1   -0.00987049 0.0104035 -0.948764   0.3427
x2   -0.00464276 0.0104296 -0.445153   0.6562
x3      0.998655 0.0103988   96.0357   <1e-99
x4      0.995159 0.0104036   95.6555   <1e-99
x5       2.01306 0.0104105   193.368   <1e-99
x6        2.0094 0.0104228   192.789   <1e-99
x7       3.00364 0.0104074   288.605   <1e-99
x8       2.99831  0.010432   287.416   <1e-99
x9        3.9967 0.0104172   383.664   <1e-99
x10      4.00196 0.0104091   384.467   <1e-99


````


