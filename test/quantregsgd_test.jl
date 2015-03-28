using OnlineStats
using Base.Test
using Distributions
println("quantregsgd_test.jl")


x = randn(100, 5)
y = vec(sum(x, 2)) + randn(100)

obj1 = QuantRegSGD(x, y, τ = .7, r = .8)
obj2 = QuantRegSGD(x, y, ones(6), τ = .7, r = .8)

for i in 1:100000
    x = randn(100, 5)
    y = vec(sum(x, 2)) + randn(100)

    update!(obj1, x, y)
    update!(obj2, x, y)
end

@test_approx_eq_eps(coef(obj1)[1], quantile(Normal(), .7), .1)
@test_approx_eq_eps(coef(obj2)[1], quantile(Normal(), .7), .1)

for i in 2:6
    @test_approx_eq_eps(coef(obj1)[i], 1, .1)
    @test_approx_eq_eps(coef(obj2)[i], 1, .1)
end
