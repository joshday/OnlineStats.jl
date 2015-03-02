using OnlineStats
using Base.Test
using Distributions

τ = [1:0.5:9]/10
obj_uniform = QuantileMM(rand(100), τ = τ, r = .7)
obj_normal = QuantileMM(randn(100), τ = τ, r = .7)

for i in 1:100000
    update!(obj_uniform, rand(100))
    update!(obj_normal, randn(100))
end

@test_approx_eq_eps(maxabs(obj_uniform.est - τ), 0, .01)
@test_approx_eq_eps(maxabs(obj_normal.est - quantile(Normal(), τ)), 0, .01)

@test size(make_df(obj_uniform), 1) == 1
@test size(make_df(obj_uniform), 2) == length(τ) + 2
