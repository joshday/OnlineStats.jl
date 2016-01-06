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


@time o = O.StatLearn(x, y, 100, algorithm = O.AdaDelta(), model = O.L1Regression())
display(o)

end
