
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
       Estimate Std.Error  t value Pr(>|t|)
x1   -0.0285202 0.0329291 -0.86611   0.3864
x2   -0.0369558  0.032942 -1.12184   0.2619
x3      1.04179 0.0329295   31.637   <1e-99
x4     0.995441 0.0329304  30.2286   <1e-99
x5       2.0251 0.0329996  61.3673   <1e-99
x6      2.03339 0.0329273  61.7539   <1e-99
x7      2.97948 0.0329615  90.3926   <1e-99
x8       3.0154 0.0329603  91.4858   <1e-99
x9      3.97433 0.0329465   120.63   <1e-99
x10      4.0016 0.0329524  121.436   <1e-99


julia> mse(fit)  # Estimate of MSE
100.1474278852499

julia> maximum(abs(beta - coef(fit)))  # Max Absolute Error
0.0417923974660932

````


