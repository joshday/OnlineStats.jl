# Playground module for testing new things in OnlineStats.  For the workflow:
# include("src/OnlineStats.jl")
# include("test/testcode.jl")

module Try
using OnlineStats, StatsBase

n = 100
y = randn(n)
w = rand(n)

o = Mean(UserWeight())
fit!(o, y, w)
@show value(o)
@show mean(y, WeightVec(w))


o = Means(5, UserWeight())
x = randn(n, 5)

fit!(o, x, w)
@show value(o)
@show mean(x, WeightVec(w), 1)


end
