module VarTest

using OnlineStats
using Base.Test
println("* var_test.jl")


# "Standard" form: Var(x1), Base.mean, Base.var, merge, merge!
n1, n2 = rand(1:1_000_000, 2)
n = n1 + n2
x1 = rand(n1)
x2 = rand(n2)
x = [x1; x2]

o = Var(x1)
@test_approx_eq o.μ mean(x1)
@test_approx_eq o.biasedvar  var(x1) * ((n1 -1) / n1)
@test o.n == n1

update!(o, x2)
@test_approx_eq o.μ  mean(x)
@test_approx_eq o.biasedvar  var(x) * ((n -1) / n)
@test o.n == n

o1 = Var(x1)
o2 = Var(x2)
o3 = merge(o1, o2)
merge!(o1, o2)
@test o1.n == o3.n
@test_approx_eq o1.μ o3.μ
@test_approx_eq o1.biasedvar o3.biasedvar

@test_approx_eq mean(x) mean(o1)
# @test_approx_eq var(x) var(o1)  # might need special batch update for Var??


# empty constructor, Base.mean, Base.var, state, copy
o = Var()
@test o.μ == 0.0
@test o.biasedvar == 0.0
@test o.n == 0
@test nobs(o) == 0
@test mean(o) == 0.0
@test var(o) == 0.0
# @test state(o) == DataFrames.DataFrame(variable = :σ² , value = 0., nobs=0)
update!(o, x1)
@test_approx_eq mean(o) mean(x1)
@test_approx_eq var(o)  var(x1)
@test o.n == n1
o1 = copy(o)
@test_approx_eq mean(o1) mean(x1)
@test_approx_eq var(o1)  var(x1)
@test o.n == n1
@test nobs(o) == n1

# clean up
x1 = x2 = x = 0;

end
