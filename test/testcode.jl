module Test
using OnlineStats

n, p = 100_000, 5
x = randn(n, p)
β = collect(0.:4.)
y = x * β + randn(n)

o = StochasticModel(x, y; algorithm = MMGrad2(r=.6), intercept = true, penalty = L1Penalty(.5))
print(coef(o))


end
