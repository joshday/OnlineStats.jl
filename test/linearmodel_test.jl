using OnlineStats
using Base.Test
using GLM
println("linearmodel_test.jl")


x = randn(100, 10)
y = vec(sum(x, 2)) + randn(100)

# First batch accuracy
obj = OnlineLinearModel(x, y)
glm = lm([ones(100) x], y)
for i in 2:11
    @test_approx_eq(coef(obj)[i], coef(glm)[i])
end


# Convergence
for i in 1:1000
    x = randn(100, 10)
    y = vec(sum(x, 2)) + randn(100)

    update!(obj, x, y)
end

for i in 2:11
    @test_approx_eq_eps(coef(obj)[i], 1, .01)
end
@test_approx_eq_eps(coef(obj)[1], 0, .01)
@test_approx_eq_eps(mse(obj), 1, .01)

