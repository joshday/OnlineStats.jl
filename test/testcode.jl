module Test
import OnlineStats
import DeprecatedOnlineStats
using StatsBase, Distributions

O = OnlineStats
D = DeprecatedOnlineStats

# srand(123)
n, p = 100_000, 20
x = randn(n, p)
β = collect(1.:p) / p - .5
y = x * β + randn(n)
β_with_int = vcat(0., β)


@time o = O.QuantReg(20)
@time fit!(o, x, y, 10)
o2 = D.QuantRegMM(20)
@time D.update!(o2, x, y)
display(o)

# println("SGD")
# O.StatLearn(x, y, algorithm = O.SGD())
# D.StochasticModel(x, y, algorithm = D.SGD(prox = true))
# @time O.StatLearn(x, y, algorithm = O.SGD())
# @time D.StochasticModel(x, y, algorithm = D.SGD(prox = true))
#
# println("")
#
# println("AdaGrad")
# O.StatLearn(x, y, algorithm = O.AdaGrad())
# D.StochasticModel(x, y, algorithm = D.ProxGrad())
# @time O.StatLearn(x, y, algorithm = O.AdaGrad())
# @time D.StochasticModel(x, y, algorithm = D.ProxGrad())

end
