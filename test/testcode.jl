module Test
import OnlineStats
import DeprecatedOnlineStats
using StatsBase, Distributions

O = OnlineStats
D = DeprecatedOnlineStats

# srand(123)
n, p = 1_000_000, 20
x = randn(n, p)
β = collect(1.:p) / p - .5
y = x * β + randn(n)
β_with_int = vcat(0., β)

@time o = O.StatLearn(x, y, algorithm = O.AdaDelta(), model = O.L1Regression())
@time o2 = O.StatLearn(x, y, O.L1Penalty(), .1, O.LearningRate2(100), O.SGD(), O.L1Regression())
println(maxabs(coef(o) - β_with_int))
println(maxabs(coef(o2) - β_with_int))

end
