using OnlineStats
using Base.Test
println("var_test.jl")

n1, n2 = rand(1:1_000_000, 2)
n = n1 + n2
x1 = rand(n1)
x2 = rand(n2)
x = [x1, x2]

obj = Var(x1)
@test obj.mean == mean(x1)
@test_approx_eq obj.var  var(x1) * ((n1 -1) / n1)
@test obj.n == n1

update!(obj, x2)
@test_approx_eq obj.mean  mean(x)
@test_approx_eq obj.var  var(x) * ((n -1) / n)
@test obj.n == n

obj1 = Var(x1)
obj2 = Var(x2)
obj3 = merge(obj1, obj2)
merge!(obj1, obj2)
@test obj1.n == obj3.n
@test_approx_eq obj1.mean obj3.mean
@test_approx_eq obj1.var obj3.var

@test_approx_eq mean(x) mean(obj1)
@test_approx_eq var(x) var(obj1)

# clean up
x1, x2, x = zeros(3)
