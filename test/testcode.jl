module Test
import OnlineStats
import OnlineStats
using StatsBase, Distributions
O = OnlineStats
O2 = OnlineStats

# srand(123)
n, p = 1_000_000, 10
x = randn(n, p)
β = collect(1.:p) / p - .5
# y = x * β + randn(n)
# y = Float64[rand(Bernoulli(1/(1+exp(-η)))) for η in x*β]
y = Float64[rand(Poisson(exp(η))) for η in x*β]
β_with_int = vcat(0., β)

o2 = O2.StochasticModel(p, algorithm = O2.ProxGrad(), model = O2.PoissonRegression())
o = O.StatLearn(p, O.LearningRate(.6), algorithm = O.MMGrad(), model = O.PoissonRegression())
oada = O.StatLearn(p, algorithm = O.AdaMMGrad(), model = O.PoissonRegression(), η = .5)

b = 100

@time O2.update!(o2, x, y, b)
@time fit!(o, x, y, b)
@time fit!(oada, x, y ,b)

display(maxabs(coef(o2) - β_with_int))
display(maxabs(coef(o) - β_with_int))
display(maxabs(coef(oada) - β_with_int))
end
