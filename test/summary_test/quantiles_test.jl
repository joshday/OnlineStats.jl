using OnlineStats
using FactCheck, Distributions

facts("Quantiles") do
    context("QuantileSGD") do

        τ = collect(1:0.5:9) / 10
        o_uniform = QuantileSGD(rand(100), LearningRate(r = .6), τ = τ)
        o_normal = QuantileSGD(randn(100), LearningRate(r = .6), τ = τ)
        @fact statenames(o_normal) --> [:quantiles, :τ, :nobs]

        n = 10_000
        for i in 1:n
            update!(o_uniform, rand(100))
            update!(o_normal, randn(100))
        end

        @fact maxabs(o_uniform.q - τ) --> roughly(0, .1)
        @fact maxabs(o_normal.q - quantile(Normal(), τ)) --> roughly(0, .1)

        @fact state(o_normal)[1] --> o_normal.q
        @fact state(o_normal)[2] --> o_normal.τ
        @fact state(o_normal)[3] --> nobs(o_normal)
        @fact statenames(o_normal) --> [:quantiles, :τ, :nobs]
        @fact nobs(o_uniform) --> 100 + n*100
        @fact nobs(o_normal) --> 100 + n*100

        QuantileSGD(0.)
    end

     context("QuantileMM") do
        τ = collect(1:0.5:9) / 10
        o_uniform = QuantileMM(rand(100), LearningRate(r = .6), τ = τ)
        o_normal = QuantileMM(randn(100), LearningRate(r = .6), τ = τ)
        @fact statenames(o_normal) --> [:quantiles, :τ, :nobs]

        n = 10_000
        for i in 1:n
            update!(o_uniform, rand(100))
            update!(o_normal, randn(100))
        end

        @fact maxabs(o_uniform.q - τ) --> roughly(0, .1)
        @fact maxabs(o_normal.q - quantile(Normal(), τ)) --> roughly(0, .1)

        @fact state(o_normal)[1] --> o_normal.q
        @fact state(o_normal)[2] --> o_normal.τ
        @fact state(o_normal)[3] --> nobs(o_normal)
        @fact statenames(o_normal) --> [:quantiles, :τ, :nobs]
        @fact o_uniform.n --> 100 + n*100
        @fact o_normal.n --> 100 + n*100
    end

    context("QuantileSort") do
        o = QuantileSort()
        o = QuantileSort(rand(100_000))
        statenames(o)
        state(o)
        quantile(o, 50)
    end
end
