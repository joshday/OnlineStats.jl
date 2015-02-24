using OnlineStats
using Base.Test

n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
x1 = rand(n1)
x2 = rand(n2)
x = [x1, x2]

ob = Summary(x1)
@test ob.mean == mean(x1)
@test ob.var == var(x1)
@test ob.max == maximum(x1)
@test ob.min == minimum(x1)
@test ob.n == n1
@test ob.nb == 1


update!(ob, x2)
@test_approx_eq ob.mean mean(x)
@test_approx_eq ob.var var(x)
@test ob.max == maximum(x)
@test ob.min == minimum(x)

# clean up
x1 = x2 = zeros(2)

