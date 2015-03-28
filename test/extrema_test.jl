using OnlineStats
using Base.Test
println("extrema_test.jl")

n1, n2 = rand(1:1_000_000, 2)
n = n1 + n2
x1 = rand(n1)
x2 = rand(n2)
x = [x1, x2]

obj = Extrema(x1)
@test obj.max == maximum(x1)
@test obj.min == minimum(x1)
@test obj.n == n1

update!(obj, x2)
@test obj.max == maximum(x)
@test obj.min == minimum(x)
@test obj.n == n

obj1 = Extrema(x1)
obj2 = Extrema(x2)
obj3 = merge(obj1, obj2)
merge!(obj1, obj2)
@test obj1.n == obj3.n
@test obj1.max == obj3.max
@test obj1.min == obj3.min
@test maximum(x) == obj3.max
@test minimum(x) == obj3.min

@test max(obj1) == maximum(obj1)
@test min(obj1) == minimum(obj1)
@test max(obj1) == maximum(x)
@test min(obj1) == minimum(x)


# clean up
x1, x2, x = zeros(3)
