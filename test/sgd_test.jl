module SGDTest

using FactCheck, OnlineStats, Distributions, Compat

function convertLogisticY(xβ)
    prob = OnlineStats.invlink(LogisticLink(), xβ)
    @compat Float64(rand(Bernoulli(prob)))
end

facts("SGD") do

    const n = 1_000_000
    const p = 50
    x = randn(n, p)
    β = collect(1.:p) / p

    atol = 0.5
    rtol = 0.1

    context("L2Regression") do
        y = x*β + randn(n)
        o = OnlineStats.SGD(x, y, model = OnlineStats.L2Regression())
        @fact coef(o) --> roughly(β, .1)
    end

    context("L1Regression") do
        y = x*β + randn(n)
        o = OnlineStats.SGD(x, y, model = OnlineStats.L1Regression())
        @fact coef(o) --> roughly(β, .1)
    end

    context("LogisticRegression") do
        y = @compat Float64[rand(Bernoulli(i)) for i in 1./(1 + exp(-x*β))]
        o = OnlineStats.SGD(x, y, model = OnlineStats.LogisticRegression())
        @fact coef(o) --> roughly(β, .1)
    end

    context("PoissonRegression") do
        y = @compat Float64[rand(Poisson(i)) for i in exp(x*β)]
        o = OnlineStats.SGD(x, y, model = OnlineStats.PoissonRegression(), η = .001)
    end

    context("QuantileRegression") do
        y = x*β + randn(n)
        o = OnlineStats.SGD(x, y, model = OnlineStats.QuantileRegression(0.5))
        @fact coef(o) --> roughly(β, .1)
    end

    context("SVMLike") do
        y = @compat Float64[rand(Bernoulli(i)) for i in 1./(1 + exp(-x*β))]
        y = 2y - 1
        o = OnlineStats.SGD(x, y, model = OnlineStats.SVMLike(), penalty = OnlineStats.L2Penalty(.01))
        pred_error = mean((predict(o,x) .> 0) .!= (y .> 0))
        @fact pred_error --> less_than(.2) "prediction error less than 20%"
    end

    context("HuberRegression") do
        const n = 1_000_000
        const p = 50
        x = randn(n, p)
        β = collect(1.:p) / p
        y = x*β + randn(n)
        o = OnlineStats.SGD(x, y, model = OnlineStats.HuberRegression(4))
        @fact coef(o) --> roughly(β, .1)
    end
end






end #module
