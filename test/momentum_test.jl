module MomentumTest

using FactCheck, StatsBase, OnlineStats, Distributions, Compat

function convertLogisticY(xβ)
    prob = OnlineStats.invlink(LogisticLink(), xβ)
    @compat Float64(rand(Bernoulli(prob)))
end

facts("Momentum") do

    const n = 1_000_000
    const p = 50
    x = randn(n, p)
    β = collect(1.:p) / p
    βtrue = vcat(0.0, β)

    atol = 0.5
    rtol = 0.1

    context("L2Regression") do
        y = x*β + randn(n)
        o = OnlineStats.Momentum(x, y, model = OnlineStats.L2Regression())
        @fact coef(o) --> roughly(βtrue, rtol = .5) "singleton"
        @fact predict(o, x) --> x * o.β + o.β0

        o = OnlineStats.Momentum(x, y, model = OnlineStats.L2Regression(), penalty = OnlineStats.L1Penalty(.01))

        # updatebatch!
        o = Momentum(p)
        onlinefit!(o, 10, x, y, batch = true)
        @fact coef(o) --> roughly(βtrue, rtol = .5) "batch"
    end

    context("L1Regression") do
        y = x*β + randn(n)
        o = OnlineStats.Momentum(x, y, model = OnlineStats.L1Regression())
        @fact coef(o) --> roughly(βtrue, rtol = .5)
        @fact predict(o, x) --> x * o.β + o.β0
    end

    context("LogisticRegression") do
        y = @compat Float64[rand(Bernoulli(i)) for i in 1./(1 + exp(-x*β))]
        o = OnlineStats.Momentum(x, y, model = OnlineStats.LogisticRegression())
        @fact coef(o) --> roughly(βtrue, rtol = .5)
        @fact predict(o, x) --> 1.0 ./ (1.0 + exp(-x * o.β - o.β0))
    end

    context("PoissonRegression") do
        y = @compat Float64[rand(Poisson(i)) for i in exp(x*β)]
        o = OnlineStats.Momentum(x, y, model = OnlineStats.PoissonRegression(), η = .00001)
        @fact predict(o, x) --> exp(x * o.β + o.β0)
    end

    context("QuantileRegression") do
        y = x*β + randn(n)
        o = OnlineStats.Momentum(x, y, model = OnlineStats.QuantileRegression(0.5))
        @fact coef(o) --> roughly(βtrue, rtol = .5)
        @fact predict(o,x) --> x * o.β + o.β0
    end

    context("SVMLike") do
        y = @compat Float64[rand(Bernoulli(i)) for i in 1./(1 + exp(-x*β))]
        y = 2y - 1
        o = OnlineStats.Momentum(x, y, model = OnlineStats.SVMLike(), penalty = OnlineStats.L2Penalty(.01))
        pred_error = mean(sign(predict(o,x)) .!= y)
        @fact pred_error --> less_than(.2)
        @fact predict(o, x) --> x * o.β + o.β0
    end

    context("HuberRegression") do
        const n = 1_000_000
        const p = 50
        x = randn(n, p)
        β = collect(1.:p) / p
        y = x*β + randn(n)
        o = OnlineStats.Momentum(x, y, model = OnlineStats.HuberRegression(4))
        @fact coef(o) --> roughly(βtrue, rtol = .5)
        @fact predict(o, x) --> x * o.β + o.β0
    end

end






end #module
