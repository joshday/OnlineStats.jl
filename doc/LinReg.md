
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
      Estimate Std.Error  t value Pr(>|t|)
x1   0.0386872 0.0329582  1.17383   0.2405
x2    0.026745 0.0329314 0.812143   0.4167
x3    0.987613 0.0329684  29.9564   <1e-99
x4    0.969854 0.0329397  29.4433   <1e-99
x5     2.07776 0.0329904  62.9807   <1e-99
x6     1.93725 0.0329715  58.7552   <1e-99
x7     2.95674 0.0329468  89.7431   <1e-99
x8     3.05069 0.0329234  92.6602   <1e-99
x9     3.99603 0.0329562  121.253   <1e-99
x10    3.97817 0.0329249  120.826   <1e-99


julia> mse(fit)  # Estimate of MSE
100.13448367997671

julia> maxabs(beta - coef(fit))  # Max Absolute Error
0.07776145627485054

````




