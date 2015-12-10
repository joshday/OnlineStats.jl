module Test
import OnlineStats
include("../deprecated/src/OnlineStats.jl")
using StatsBase, Distributions

O = OnlineStats
D = DeprecatedOnlineStats

# srand(123)
n, p = 1_000_000, 10
x = randn(n, p)
β = collect(1.:p) / p - .5
y = x * β + randn(n)
# y = Float64[rand(Bernoulli(1/(1+exp(-η)))) for η in x*β]
# y = Float64[rand(Poisson(exp(η))) for η in x*β]
β_with_int = vcat(0., β)

@time D.StochasticModel(x, y)
@time O.StatLearn(x, y, 10)
end
