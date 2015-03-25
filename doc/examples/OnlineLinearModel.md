
# OnlineLinearModel


````julia
using OnlineStats
using StatsBase
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

fit = OnlineLinearModel(x, y, int=false)
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
      Estimate Std.Error  t value Pr(>|t|)
x1    0.021879 0.0329296 0.664416   0.5064
x2   0.0450272  0.032934  1.36719   0.1716
x3     1.02388 0.0329383  31.0848   <1e-99
x4    0.968289 0.0328991   29.432   <1e-99
x5     1.99559 0.0329213  60.6169   <1e-99
x6     1.94501 0.0329277   59.069   <1e-99
x7     2.93215 0.0328973  89.1304   <1e-99
x8     3.06852 0.0329039  93.2571   <1e-99
x9     3.96659 0.0329007  120.562   <1e-99
x10    4.05542 0.0329173    123.2   <1e-99


julia> mse(fit)  # Estimate of MSE
99.9906534409307

julia> maxabs(beta - coef(fit))  # Max Absolute Error
0.0685194441904371

````


