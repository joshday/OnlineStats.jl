module OnlineStatsBenchmarks

import OnlineStats, GLM, GLMNet, Regression, MultivariateStats, Lasso
using Benchmarks

# simulate data
n, p = 100_000, 50
x = randn(n, p)
β = collect(1.:p)
y = x * β + randn(n)

# Get benchmarks
time_GLM                = @benchmark GLM.lm(x, y)
time_GLMNet             = @benchmark GLMNet.glmnet(x, y, lambda = [0.])
time_Lasso              = @benchmark Lasso.fit(Lasso.LassoPath, x, y, λ = [0.])
time_MultivariateStats  = @benchmark MultivariateStats.llsq(x, y, bias = false)
time_OnlineStats        = @benchmark OnlineStats.LinReg(x, y)
time_OnlineStats2       = @benchmark OnlineStats.StatLearn(x, y)
time_Regression         = @benchmark Regression.llsq(x, y)

# print times
println("GLM:               ", time_GLM.time_used)
println("GLMNet:            ", time_GLMNet.time_used)
println("Lasso:             ", time_Lasso.time_used)
println("MultivariateStats: ", time_MultivariateStats.time_used)
println("OnlineStats:       ", time_OnlineStats.time_used)
println("OnlineStats2:      ", time_OnlineStats2.time_used)
println("Regression:        ", time_Regression.time_used)


end
