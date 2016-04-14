module Performance
reload("OnlineStats")
using OnlineStats

using  StatsBase
n, p = 100_000, 10
x = randn(n, p)
y = x * collect(1.:p) + randn(n)

o = LinReg(x, y)  # NoPenalty() by default
coef(o)
predict(o, x)
confint(o, .95)
vcov(o)
stderr(o)
coeftable(o)


@show coef(o, RidgePenalty(.1))
@show coef(o, LassoPenalty(.1))
@show coef(o, ElasticNetPenalty(.1, .5))
@show coef(o, SCADPenalty(.1, 3.7))

end # module
