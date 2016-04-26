module Experiments
# reload("OnlineStats")
using OnlineStats, StatsBase

n, p = 1_000_000, 5
x = randn(n, p)
y = x * collect(1.:p) + randn(n)

@time o = StatLearn(x, y, AdaDelta())
@show coef(o)
@time o = StatLearn(x, y, 5, AdaDelta())
@show coef(o)




end
