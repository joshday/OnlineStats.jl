module RDATest

using FactCheck, StatsBase, OnlineStats, Distributions, Compat


facts("RDA") do

    const n = 1_000_000
    const p = 50
    x = randn(n, p)
    β = collect(1.:p) / p
    βtrue = vcat(0.0, β)

    atol = 0.5
    rtol = 0.1

    context("L2Regression") do
        y = x*β + randn(n)
        o = OnlineStats.RDA(x, y, model = OnlineStats.L2Regression())
        @fact coef(o) --> roughly(βtrue, .5)
        @fact predict(o, x) --> x * o.β + o.β0

        o = OnlineStats.RDA(x, y, model = OnlineStats.L2Regression(), penalty = OnlineStats.L1Penalty(.01))
    end

    context("L1Regression") do
        y = x*β + randn(n)
        o = OnlineStats.RDA(x, y, model = OnlineStats.L1Regression())
        @fact coef(o) --> roughly(βtrue, rtol = .5)
        @fact predict(o, x) --> x * o.β + o.β0
    end

    context("LogisticRegression") do
        y = @compat Float64[rand(Bernoulli(i)) for i in 1./(1 + exp(-x*β))]
        o = OnlineStats.RDA(x, y, model = OnlineStats.LogisticRegression())
        @fact coef(o) --> roughly(βtrue, rtol = .5)
        @fact predict(o, x) --> 1.0 ./ (1.0 + exp(-(x * o.β + o.β0)))
    end

    context("PoissonRegression") do
        y = @compat Float64[rand(Poisson(i)) for i in exp(x*β)]
        o = OnlineStats.RDA(x, y, model = OnlineStats.PoissonRegression())
        @fact predict(o, x) --> exp(x * o.β + o.β0)
    end

    context("QuantileRegression") do
        y = x*β + randn(n)
        o = OnlineStats.RDA(x, y, model = OnlineStats.QuantileRegression(0.5))
        @fact coef(o) --> roughly(βtrue, rtol = .5)
        @fact predict(o,x) --> x * o.β + o.β0
    end

    context("SVMLike") do
        y = @compat Float64[rand(Bernoulli(i)) for i in 1./(1 + exp(-x*β))]
        y = 2y - 1
        o = OnlineStats.RDA(x, y, model = OnlineStats.SVMLike(), penalty = OnlineStats.L2Penalty(.01))
        pred_error = mean((predict(o, x) .> 0) .!= (y .> 0))
        @fact pred_error --> less_than(.2)
        @fact predict(o, x) --> x * o.β + o.β0
    end

    context("HuberRegression") do
        const n = 1_000_000
        const p = 50
        x = randn(n, p)
        β = collect(1.:p) / p
        y = x*β + randn(n)
        o = OnlineStats.RDA(x, y, model = OnlineStats.HuberRegression(4))
        @fact coef(o) --> roughly(βtrue, rtol = .5)
        @fact predict(o, x) --> x * o.β + o.β0
    end

    context("LASSO update") do
        # Need more and better tests
        y = x*β + randn(n)
        o = OnlineStats.RDA(x, y, penalty = OnlineStats.L1Penalty(.01))
        o2 = OnlineStats.RDA(x, y)
        for i in 2:p
            @fact coef(o)[p] --> less_than(coef(o2)[p])
        end

        o = OnlineStats.RDA(p, penalty = L1Penalty(.1))
        @fact_throws L1Penalty(-100)
        @fact_throws(L1Penalty(.1, -1))
        L1Penalty(.1, 200)
    end
end






end #module
