using OnlineStats
using Base.Test
using Distributions
println("fivenumber_test.jl")

obj_uniform = FiveNumberSummary(rand(100), r = .7)
obj_normal = FiveNumberSummary(randn(100), r = .7)

for i in 1:10000
    update!(obj_uniform, rand(100))
    update!(obj_normal, randn(100))
end

@test obj_uniform.n == 100 + 10000*100
@test obj_uniform.nb == 10001

@test_approx_eq_eps(obj_uniform.min, 0, .001)
@test_approx_eq_eps(obj_uniform.quantile.est[1], 0.25, .01)
@test_approx_eq_eps(obj_uniform.quantile.est[2], 0.5, .01)
@test_approx_eq_eps(obj_uniform.quantile.est[3], 0.75, .01)
@test_approx_eq_eps(obj_uniform.max, 1, .001)

@test_approx_eq_eps(obj_normal.quantile.est[1], quantile(Normal(), 0.25), .01)
@test_approx_eq_eps(obj_normal.quantile.est[2], quantile(Normal(), 0.5), .01)
@test_approx_eq_eps(obj_normal.quantile.est[3], quantile(Normal(), 0.75), .01)


y1 = rand(100)
y2 = rand(100)
obj1 = FiveNumberSummary(y1)
obj2 = FiveNumberSummary(y2)
obj3 = merge(obj1, obj2)
merge!(obj1, obj2)

@test obj1.n == obj3.n
@test obj1.nb == obj3.nb
@test obj1.min == obj3.min
@test obj1.max == obj3.max
@test obj1.n == 200
@test obj1.nb == 2
@test obj1.max == maximum([y1; y2])
@test obj1.min == minimum([y1; y2])
