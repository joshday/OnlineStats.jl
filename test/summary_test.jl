using OnlineStats
using Base.Test

n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
x1 = rand(n1)
x2 = rand(n2)
x = [x1, x2]

ob = Summary(x1)
@test ob.mean.mean == mean(x1)
@test_approx_eq ob.var.var var(x1) * (n1 - 1) / n1
@test ob.extrema.max == maximum(x1)
@test ob.extrema.min == minimum(x1)
@test ob.n == n1

update!(ob, x2)
@test_approx_eq ob.mean.mean mean(x)
@test_approx_eq_eps(ob.var.var, var(x) * (ob.n - 1) / ob.n, 1e-6)
@test ob.extrema.max == maximum(x)
@test ob.extrema.min == minimum(x)

ob = Summary(x1)
ob2 = Summary(x2)
ob3 = merge(ob, ob2)
@test_approx_eq ob3.mean.mean mean(x)
@test_approx_eq_eps(ob3.var.var, var(x) * (ob.n - 1) / ob.n, 1e-6)
@test ob3.extrema.max == maximum(x)
@test ob3.extrema.min == minimum(x)

merge!(ob, ob2)
@test ob.mean.mean == ob3.mean.mean
@test_approx_eq ob.var.var ob3.var.var
@test ob.extrema.max == ob3.extrema.max
@test ob.extrema.min == ob3.extrema.min
@test ob.n == ob3.n

# clean up
x1, x2, x = zeros(3)

