using OnlineStats
using Base.Test



# Simulate data
x1 = randn(1000)
x2 = randn(1000)

# oMean
obj = oMean(x1)
@test obj.statistic == "mean"
@test obj.n == 1000

