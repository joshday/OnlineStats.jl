
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
        Estimate  Std.Error   t value Pr(>|t|)
x1   -0.00288898 0.00329453 -0.876902   0.3805
x2   -0.00183379 0.00329344 -0.556801   0.5777
x3      0.995718  0.0032899   302.659   <1e-99
x4      0.998983 0.00329349    303.32   <1e-99
x5       2.00153 0.00329132   608.126   <1e-99
x6       1.99919  0.0032921   607.269   <1e-99
x7       3.00533 0.00329577   911.875   <1e-99
x8       2.99772 0.00329216   910.562   <1e-99
x9       4.00043 0.00328916   1216.25   <1e-99
x10      4.00463 0.00329491    1215.4   <1e-99


julia> maximum(abs2(coef(fit) - beta))
2.8410417694818726e-5

````


