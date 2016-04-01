# Playground module for testing new things in OnlineStats.  For the workflow:
# include("src/OnlineStats.jl")
# include("test/testcode.jl")

module Try
using OnlineStats, StatsBase

n = 1000
y = randn(n)
wts = rand(n)

o = WeightedOnlineStat(Mean)
fit!(o, y, wts)
value(o)

y2 = randn(n, 5)
o = WeightedOnlineStat(CovMatrix, 5)
fit!(o, y2, wts)
value(o)


end
