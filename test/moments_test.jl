using OnlineStats
using Base.Test

n1, n2 = rand(1:1_000_000, 2)
n = n1 + n2
x1 = rand(n1)
x2 = rand(n2)
x = [x1, x2]

obj = Moments(x1)
@test mean(obj) == mean(x1)
@test_approx_eq var(obj)  var(x1)
@test_approx_eq_eps(skewness(obj), skewness(x1) * (obj.n / (obj.n - 1)), 1e-2)
@test_approx_eq_eps(kurtosis(obj), kurtosis(x1), 1e-2)
@test obj.n == n1

update!(obj, x2)
@test_approx_eq mean(obj)  mean(x)
@test_approx_eq var(obj)  var(x)
@test_approx_eq_eps(skewness(obj), skewness(x) * (obj.n / (obj.n - 1)), 1e-2)
@test_approx_eq_eps(kurtosis(obj), kurtosis(x), 1e-2)
@test obj.n == n

obj1 = Moments(x1)
obj2 = Moments(x2)
obj3 = merge(obj1, obj2)
merge!(obj1, obj2)
@test obj1.n == obj3.n
@test obj1.n == length(x)
@test_approx_eq mean(obj1) mean(obj3)
@test_approx_eq var(obj1) var(obj3)

@test_approx_eq_eps(mean(x), mean(obj1), 1e-2)
@test_approx_eq_eps(var(x), var(obj1), 1e-2)

# clean up
x1, x2, x = zeros(3)
