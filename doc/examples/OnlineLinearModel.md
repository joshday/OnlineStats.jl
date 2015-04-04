
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
       Estimate Std.Error   t value Pr(>|t|)
x1   -0.0128542 0.0329464 -0.390154   0.6964
x2   -0.0126134 0.0329244 -0.383101   0.7016
x3       1.0324 0.0328673    31.411   <1e-99
x4      1.01067 0.0329361   30.6858   <1e-99
x5      2.03489 0.0328994   61.8521   <1e-99
x6      2.02631 0.0329088   61.5736   <1e-99
x7      2.99978 0.0329443   91.0563   <1e-99
x8      2.96113 0.0329345   89.9098   <1e-99
x9       4.0118 0.0328924   121.968   <1e-99
x10     3.96838 0.0329123   120.574   <1e-99


julia> mse(fit)  # Estimate of MSE
100.01596200735125

julia> maxabs(beta - coef(fit))  # Max Absolute Error
0.038869753866142887

````


