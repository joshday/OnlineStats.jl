
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
x1   0.00673943  0.032897 0.204865   0.8377
x2     0.020548 0.0328929 0.624694   0.5322
x3     0.996412 0.0329178  30.2697   <1e-99
x4      1.01598 0.0329307  30.8522   <1e-99
x5      2.00269 0.0329111  60.8514   <1e-99
x6      2.00232 0.0328969  60.8666   <1e-99
x7      2.96303  0.032908  90.0397   <1e-99
x8      3.04839 0.0329184  92.6045   <1e-99
x9      3.98297 0.0329001  121.062   <1e-99
x10     3.98067 0.0329139  120.942   <1e-99


julia> mse(fit)  # Estimate of MSE
99.92735319991426

julia> maxabs(beta - coef(fit))  # Max Absolute Error
0.048391832668188695

````


