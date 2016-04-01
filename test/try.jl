# Playground module for testing new things in OnlineStats.  For the workflow:
# include("src/OnlineStats.jl")
# include("test/testcode.jl")

module Try
using OnlineStats, StatsBase

n = 1000
y = randn(n)
wts = rand(n)

# ScalarInput
o = WeightedOnlineStat(Mean)
fit!(o, y, wts)

@show mean(o.o)
@show mean(y, WeightVec(wts))

# VectorInput
y2 = randn(n, 3)


o2 = WeightedOnlineStat(CovMatrix, 3)
fit!(o2, y2, wts)

@show cov(o2.o)
@show cov(y2, WeightVec(wts))




end
