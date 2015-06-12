using OnlineStats
using FactCheck, Distributions

facts("Quantiles") do
    context("QuantileSGD") do
        τ = [1:0.5:9]/10
        o_uniform = QuantileSGD(rand(100), StochasticWeighting(.8), τ = τ)
        o_normal = QuantileSGD(randn(100), StochasticWeighting(.8), τ = τ)
        @fact statenames(o_normal) => [:quantiles, :τ, :nobs]

        for i in 1:100_000
            update!(o_uniform, rand(100))
            updatebatch!(o_normal, randn(100))
        end

        @fact maxabs(o_uniform.q - τ) => roughly(0, .1)
        @fact maxabs(o_normal.q - quantile(Normal(), τ)) => roughly(0, .1)

        @fact state(o_normal)[1] => o_normal.q
        @fact state(o_normal)[2] => o_normal.τ
        @fact state(o_normal)[3] => nobs(o_normal)
        @fact statenames(o_normal) => [:quantiles, :τ, :nobs]
        @fact nobs(o_uniform) => 100 + 10000*100
        @fact nobs(o_normal) => 100 + 10000*100

        QuantileSGD(0.)
    end

     context("QuantileMM") do
        τ = [1:0.5:9]/10
        o_uniform = QuantileMM(rand(100), StochasticWeighting(.8), τ = τ)
        o_normal = QuantileMM(randn(100), StochasticWeighting(.8), τ = τ)
        @fact statenames(o_normal) => [:quantiles, :τ, :nobs]

        for i in 1:100_000
            update!(o_uniform, rand(100))
            updatebatch!(o_normal, randn(100))
        end

        @fact maxabs(o_uniform.q - τ) => roughly(0, .1)
        @fact maxabs(o_normal.q - quantile(Normal(), τ)) => roughly(0, .1)

        @fact state(o_normal)[1] => o_normal.q
        @fact state(o_normal)[2] => o_normal.τ
        @fact state(o_normal)[3] => nobs(o_normal)
        @fact statenames(o_normal) => [:quantiles, :τ, :nobs]
        @fact o_uniform.n => 100 + 10000*100
        @fact o_normal.n => 100 + 10000*100

        QuantileMM(0.)
    end
end

