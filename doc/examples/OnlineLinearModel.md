
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
x1    -0.0160104 0.0329177 -0.486377   0.6267
x2   -0.00519732 0.0329073 -0.157938   0.8745
x3      0.957218 0.0329276   29.0704   <1e-99
x4       1.02447 0.0329098   31.1297   <1e-99
x5       2.03038 0.0329289   61.6595   <1e-99
x6       2.01366 0.0329321   61.1458   <1e-99
x7       3.02854 0.0329368   91.9499   <1e-99
x8       2.99148  0.032929   90.8463   <1e-99
x9       4.01757 0.0329452   121.947   <1e-99
x10      3.96243 0.0329258   120.344   <1e-99


julia> mse(fit)  # Estimate of MSE
100.02608370105064

julia> maxabs(beta - coef(fit))  # Max Absolute Error
0.042782365197986394

````


