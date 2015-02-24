
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
x1   -0.00766162 0.0103822 -0.737955   0.4605
x2    0.00321506 0.0103895  0.309454   0.7570
x3      0.993764 0.0104025   95.5316   <1e-99
x4       1.01394 0.0103809    97.674   <1e-99
x5       1.99548 0.0103788   192.264   <1e-99
x6       2.00482 0.0104037   192.702   <1e-99
x7       2.98374 0.0104094   286.639   <1e-99
x8       3.00478  0.010385   289.337   <1e-99
x9         4.003 0.0103814   385.594   <1e-99
x10      4.00217 0.0103692   385.966   <1e-99


````


