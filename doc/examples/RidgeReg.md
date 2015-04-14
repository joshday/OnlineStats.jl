
# RidgeReg


````julia
using OnlineStats, StatsBase, Gadfly, Distributions, DataFrames, RDatasets
````





### Get Boston Housing data
````julia
dt = dataset("MASS", "Boston")
y = array(dt[:MedV])
x = array(dt[:, 1:end-1])

y = convert(Vector{Float64}, y)
x = convert(Matrix{Float64}, x)
````





### Create model with the first batch
````julia
batch = 1:2
fit = RidgeReg(x[batch,:], y[batch], int=false)
````





### Update model with many batches
````julia
for i = 2:length(y)/2
    batch += 2
    update!(fit, x[batch, :], y[batch])
end
````





### Check fit
````julia
julia> coeftable(fit)
        Estimate  Std.Error    t value Pr(>|t|)
x1    -0.0928965   0.034421   -2.69883   0.0072
x2      0.048715  0.0144033     3.3822   0.0008
x3   -0.00405998  0.0644397 -0.0630044   0.9498
x4         2.854   0.903913    3.15738   0.0017
x5      -2.86844    3.35873  -0.854024   0.3935
x6       5.92815   0.309109    19.1782   <1e-60
x7   -0.00726933  0.0138145  -0.526209   0.5990
x8     -0.968514    0.19563   -4.95074    <1e-5
x9      0.171151  0.0667524    2.56397   0.0106
x10  -0.00939622 0.00392309   -2.39511   0.0170
x11    -0.392191   0.109869   -3.56961   0.0004
x12    0.0149056 0.00269654    5.52769    <1e-7
x13    -0.416304  0.0507862   -8.19719   <1e-14


julia> coeftable(fit, 1) # coefficients when λ = 1
        Estimate  Std.Error   t value Pr(>|t|)
x1    -0.0927108   0.034483   -2.6886   0.0074
x2     0.0490546  0.0144262   3.40037   0.0007
x3   -0.00874646  0.0637553 -0.137188   0.8909
x4       2.75502    0.89071   3.09306   0.0021
x5      -1.87289    2.78921 -0.671478   0.5022
x6       5.86819   0.296907   19.7644   <1e-63
x7   -0.00787895  0.0136887  -0.57558   0.5652
x8     -0.959196   0.195469  -4.90714    <1e-5
x9      0.171845  0.0668645   2.57005   0.0105
x10  -0.00960388 0.00391379  -2.45386   0.0145
x11    -0.389557   0.109985   -3.5419   0.0004
x12    0.0148772  0.0026969   5.51641    <1e-7
x13    -0.422148  0.0501877   -8.4114   <1e-15


````





### Solution path
````julia
path = [coef(fit, 0)' 0]
for i in 0:10000
    path = [path; [coef(fit, i)' i]]
end

df = melt(convert(DataFrame, path), 14)
names!(df, [:variable, :value, :λ])
plot(df, x=:λ, y=:value, color=:variable, Geom.line)
````


![](figures/RidgeReg_6_1.png)


