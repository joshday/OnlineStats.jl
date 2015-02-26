
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
       Estimate Std.Error  t value Pr(>|t|)
x1    0.0369854 0.0329491   1.1225   0.2616
x2   -0.0631285 0.0329397 -1.91649   0.0553
x3       1.0017 0.0329304  30.4187   <1e-99
x4     0.977041 0.0329423  29.6592   <1e-99
x5      1.96861  0.032987  59.6784   <1e-99
x6      2.04808 0.0329413  62.1735   <1e-99
x7      2.98915 0.0329546  90.7049   <1e-99
x8      3.03893 0.0329451  92.2423   <1e-99
x9      3.94405 0.0329591  119.665   <1e-99
x10     4.05647 0.0329643  123.056   <1e-99


julia> mse(fit)  # Estimate of MSE
100.15710944758459

julia> maximum(abs(beta - coef(fit)))  # Max Absolute Error
0.0631285475847107

````


