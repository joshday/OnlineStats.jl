# Playground module for testing new things in OnlineStats.  For the workflow:
# include("src/OnlineStats.jl")
# include("test/testcode.jl")

module Try
import OnlineStats
using StatsBase
O = OnlineStats

n = 100
y = randn(n)
w = rand(n)

@show mean(y, WeightVec(w))

o = O.Mean(O.UserWeight())
fit!(o, y, w)
@show O.value(o)


end
