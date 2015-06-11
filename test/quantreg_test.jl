module QuantileRegressionTest

using FactCheck
using OnlineStats
using StatsBase
using Distributions


facts("Quantile Regression") do
    context("QuantRegSGD") do
        x = [ones(100) randn(100, 5)]
        y = vec(sum(x[:, 2:end], 2)) + randn(100)
        o = QuantRegSGD(x, y)
        updatebatch!(o, x, y)

        o1 = QuantRegSGD(x, y, StochasticWeighting(.9), τ = .7)
        o2 = QuantRegSGD(x, y, StochasticWeighting(.9), τ = .7, start = ones(6))

        for i in 1:10000
            x = [ones(100) randn(100, 5)]
            y = vec(sum(x[:, 2:end], 2)) + randn(100)

            update!(o1, x, y)
            update!(o2, x, y)
        end

        @fact coef(o1)[1] => roughly(quantile(Normal(), .7), .1)
        @fact coef(o2)[1] => roughly(quantile(Normal(), .7), .1)

        for i in 2:6
            @fact coef(o1)[i] => roughly(1, .1)
            @fact coef(o2)[i] => roughly(1, .1)
        end

        @fact statenames(o1) => [:β, :τ, :nobs]
        @fact state(o1) => Any[copy(o1.β), o1.τ, nobs(o1)]
    end

     context("QuantRegMM") do
        x = [ones(100) randn(100, 5)]
        y = vec(sum(x[:, 2:end], 2)) + randn(100)

        o1 = QuantRegMM(x, y, StochasticWeighting(.9), τ = .7)
        o2 = QuantRegMM(x, y, StochasticWeighting(.9), τ = .7, start = ones(6))

        for i in 1:10000
            x = [ones(100) randn(100, 5)]
            y = vec(sum(x[:, 2:end], 2)) + randn(100)

            update!(o1, x, y)
            update!(o2, x, y)
        end

        @fact coef(o1)[1] => roughly(quantile(Normal(), .7), .1)
        @fact coef(o2)[1] => roughly(quantile(Normal(), .7), .1)

        for i in 2:6
            @fact coef(o1)[i] => roughly(1, .1)
            @fact coef(o2)[i] => roughly(1, .1)
        end

        @fact statenames(o1) => [:β, :τ, :nobs]
        @fact state(o1) => Any[copy(o1.β), o1.τ, nobs(o1)]
    end
end

end # module
