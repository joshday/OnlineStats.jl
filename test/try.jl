# Playground module for testing new things in OnlineStats.  For the workflow:
# include("src/OnlineStats.jl")
# include("test/testcode.jl")

module Try
using OnlineStats, StatsBase, Benchmarks
import OnlineStats2; O2 = OnlineStats2

n = 100_000
y = randn(n)
w = rand(n)

o1 = Mean()
o2 = O2.Mean()

@time fit!(o1, y, w ./ cumsum(w))
@show value(o1) - mean(y, WeightVec(w))

end
