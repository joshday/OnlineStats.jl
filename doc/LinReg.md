
# LinReg


````julia
using OnlineStats, StatsBase
````





### Make true beta
````julia
p = 10
beta = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4]
````





### Create model with the first batch
````julia
srand(621)
X = rand(100, p)
y = X * beta + 10 * randn(100)

fit = LinReg(X, y)
````





### Update model with many batches
````julia
for i = 1:10000
    rand!(X)
    y = X * beta + 10 * randn(100)
    updatebatch!(fit, X, y)
end
````





### Check fit
````julia
julia> coeftable(fit)  # CoefTable
       Estimate Std.Error   t value Pr(>|t|)
x1   -0.0154153 0.0329335 -0.468074   0.6397
x2   -0.0167972 0.0329494 -0.509788   0.6102
x3      1.01152 0.0329062   30.7395   <1e-99
x4      1.00613 0.0329346   30.5494   <1e-99
x5      1.96584 0.0329213   59.7132   <1e-99
x6      2.01685 0.0329347   61.2377   <1e-99
x7       3.0115 0.0329266   91.4611   <1e-99
x8      2.97585 0.0329215   90.3923   <1e-99
x9      4.03853 0.0329418   122.596   <1e-99
x10     4.01992 0.0329599   121.964   <1e-99


julia> mse(fit)  # Estimate of MSE
100.07285232559364

julia> maxabs(beta - coef(fit))  # Max Absolute Error
0.03853378064706625

````




