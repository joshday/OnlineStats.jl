using OnlineStats
using Base.Test
println("* summary_test.jl")


# Summary(x1), merge, merge!, mean, var, max, min
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

@test state(ob) == DataFrames.DataFrame(
    variable = [:μ, :σ², :max, :min],
    value = [mean(ob), var(ob), maximum(x1), minimum(x1)],
    n = nobs(ob))

update!(ob, x2)
@test_approx_eq ob.mean.mean mean(x)
@test_approx_eq(ob.var.var, var(x) * (ob.n - 1) / ob.n)
@test ob.extrema.max == maximum(x)
@test ob.extrema.min == minimum(x)
@test ob.n == n1 + n2

ob = Summary(x1)
ob2 = Summary(x2)
ob3 = merge(ob, ob2)
@test_approx_eq ob3.mean.mean mean(x)
@test_approx_eq(ob3.var.var, var(x) * (ob3.n - 1) / ob3.n)
@test ob3.extrema.max == maximum(x)
@test ob3.extrema.min == minimum(x)

merge!(ob, ob2)
@test_approx_eq ob.mean.mean  ob3.mean.mean
@test_approx_eq ob.var.var  ob3.var.var
@test ob.extrema.max == ob3.extrema.max
@test ob.extrema.min == ob3.extrema.min
@test ob.n == ob3.n

@test_approx_eq mean(ob) mean(x)
@test_approx_eq var(ob) var(x)
@test max(ob) == maximum(x)
@test min(ob) == minimum(x)




# clean up
x1 = x2 = x = 0;

