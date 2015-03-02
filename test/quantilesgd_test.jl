using OnlineStats
using Base.Test
using Distributions

τ = [1:0.5:9]/10
obj_uniform = QuantileSGD(rand(100), τ = τ, r = .8)
obj_normal = QuantileSGD(randn(100), τ = τ, r = .8)

for i in 1:100000
    update!(obj_uniform, rand(100))
    update!(obj_normal, randn(100))
end

@test_approx_eq_eps(maxabs(obj_uniform.est - τ), 0, .01)
@test_approx_eq_eps(maxabs(obj_normal.est - quantile(Normal(), τ)), 0, .01)

@test size(make_df(obj_uniform), 1) == 1
@test size(make_df(obj_uniform), 2) == length(τ) + 2
@test obj_uniform.n == 100 + 10000*100
@test obj_uniform.nb == 10001



x, y = rand(100), rand(100)
obj1 = QuantileSGD(x)
obj2 = QuantileSGD(y)
obj3 = merge(obj1, obj2)
merge!(obj1, obj2)

for i in 1:3
    @test obj1.est[i] == obj3.est[i]
    @test obj1.τ[i] == obj3.τ[i]
    @test obj1.τ[i] == obj2.τ[i]
end
@test obj1.n == 200
@test obj1.nb == 2
@test obj3.n == 200
@test obj3.nb == 2
