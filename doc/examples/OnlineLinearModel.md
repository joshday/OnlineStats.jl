
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
x1   -0.00291271 0.00329123 -0.884993   0.3762
x2    0.00403809 0.00329489   1.22556   0.2204
x3       1.00611 0.00329526    305.32   <1e-99
x4       0.99671 0.00329604   302.396   <1e-99
x5       1.99977 0.00329466   606.973   <1e-99
x6       1.99889  0.0032913   607.326   <1e-99
x7       3.00016 0.00329275    911.14   <1e-99
x8       2.99824 0.00329188   910.799   <1e-99
x9       4.00293 0.00329492   1214.88   <1e-99
x10      3.99847 0.00329339   1214.09   <1e-99


julia> maximum(abs2(coef(fit) - beta))
3.7317044316753414e-5

````


