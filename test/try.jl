# Playground module for testing new things in OnlineStats.  For the workflow:
# include("src/OnlineStats.jl")
# include("test/testcode.jl")

module Try
using OnlineStats, StatsBase, Benchmarks
import OnlineStats2; O2 = OnlineStats2

n = 1_000_000
y = randn(n)
wts = rand(n)

o1 = Mean()
o2 = O2.Mean()

@show @benchmark fit!(o1, y)
@show @benchmark O2.fit!(o2, y)


end
