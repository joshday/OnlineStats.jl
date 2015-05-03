using OnlineStats
using FactCheck, Distributions

facts("Quantiles") do
    context("QuantileSGD") do
        τ = [1:0.5:9]/10
        obj_uniform = QuantileSGD(rand(100), StochasticWeighting(.8), τ = τ)
        obj_normal = QuantileSGD(randn(100), StochasticWeighting(.8), τ = τ)
        @fact statenames(obj_normal) => [:quantiles, :τ, :nobs]

        for i in 1:100_000
            update!(obj_uniform, rand(100))
            update!(obj_normal, randn(100))
        end

        @fact maxabs(obj_uniform.q - τ) => roughly(0, .01)
        @fact maxabs(obj_normal.q - quantile(Normal(), τ)) => roughly(0, .01)

        @fact state(obj_normal)[1] => obj_normal.q
        @fact state(obj_normal)[2] => obj_normal.τ
        @fact state(obj_normal)[3] => nobs(obj_normal)
        @fact statenames(obj_normal) => [:quantiles, :τ, :nobs]
        @fact obj_uniform.n => 100 + 100000*100
        @fact obj_normal.n => 100 + 100000*100
    end

     context("QuantileMM") do
        τ = [1:0.5:9]/10
        obj_uniform = QuantileMM(rand(100), StochasticWeighting(.8), τ = τ)
        obj_normal = QuantileMM(randn(100), StochasticWeighting(.8), τ = τ)
        @fact statenames(obj_normal) => [:quantiles, :τ, :nobs]

        for i in 1:100_000
            update!(obj_uniform, rand(100))
            update!(obj_normal, randn(100))
        end

        @fact maxabs(obj_uniform.q - τ) => roughly(0, .01)
        @fact maxabs(obj_normal.q - quantile(Normal(), τ)) => roughly(0, .01)

        @fact state(obj_normal)[1] => obj_normal.q
        @fact state(obj_normal)[2] => obj_normal.τ
        @fact state(obj_normal)[3] => nobs(obj_normal)
        @fact statenames(obj_normal) => [:quantiles, :τ, :nobs]
        @fact obj_uniform.n => 100 + 100000*100
        @fact obj_normal.n => 100 + 100000*100
    end
end

