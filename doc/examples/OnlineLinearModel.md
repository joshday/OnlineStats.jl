
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
x1   -0.0239866 0.0328928 -0.729235   0.4659
x2   0.00722398 0.0329076  0.219523   0.8262
x3      1.06703 0.0329174   32.4152   <1e-99
x4       1.0025 0.0329119     30.46   <1e-99
x5      2.00166 0.0329329   60.7799   <1e-99
x6      1.97782 0.0328985   60.1187   <1e-99
x7      2.94456 0.0329262   89.4292   <1e-99
x8      3.05505 0.0328749   92.9296   <1e-99
x9      3.99219 0.0329194   121.272   <1e-99
x10     3.97338 0.0328993   120.774   <1e-99


julia> mse(fit)  # Estimate of MSE
99.86572535906181

julia> maxabs(beta - coef(fit))  # Max Absolute Error
0.06702661567407442

````


