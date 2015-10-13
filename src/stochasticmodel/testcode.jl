########################################################
module TestMyCode
using OnlineStats
n,p = 1_000_000, 20
x = randn(n, p)
β = collect(1.:p)
y = x*β + randn(n)

# run once to compile
o = StochasticModel(x, y)
# o2 = OnlineStats.SGModel(x, y)

# get times
@time o = StochasticModel(x, y, loss=L1Loss())
# @time o2 = OnlineStats.SGModel(x, y)

println(o.β)
end # module
