
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
for i = 1:10000
    x = rand(100, p)
    y = x * beta + randn(100)
    update!(fit, x, y)
end
````





### Check fit
````julia
julia> coeftable(fit)
        Estimate  Std.Error  t value Pr(>|t|)
x1   -0.00218585 0.00329199 -0.66399   0.5067
x2   0.000523373 0.00329001 0.159079   0.8736
x3      0.999445 0.00328875  303.898   <1e-99
x4      0.994569 0.00328777  302.506   <1e-99
x5       2.00208  0.0032905  608.442   <1e-99
x6        1.9962  0.0032882  607.079   <1e-99
x7        3.0015 0.00328963  912.412   <1e-99
x8       3.00279 0.00329109  912.401   <1e-99
x9        4.0032 0.00329366  1215.43   <1e-99
x10      4.00149 0.00329036  1216.13   <1e-99


julia> maximum(abs(coef(fit) - beta))
0.005430623661930589

````


