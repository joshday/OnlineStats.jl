module Experiments
reload("OnlineStats")
using OnlineStats, StatsBase

n, p = 100_000, 5
x = randn(n, p)
y = x * collect(1.:p) + randn(n)


o = StatLearn(p, ADAM())
@time fit!(o, x, y, 5)
@time o2 = StatLearn(x, y, MMGrad())

@show coef(o)
@show coef(o2)



end
