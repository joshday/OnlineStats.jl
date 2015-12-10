module StatLearnTest

using TestSetup, OnlineStats, Distributions, FactCheck
import OnlineStats: _j

facts(@title "StatLearn") do
    n, p = 1_000, 10
    x = randn(n, p)
    β = collect(linspace(-1, 1, p))

    context(@subtitle "L2Regression") do
        y = x*β + randn(n)
        StatLearn(x, y)
        StatLearn(x, y, 10)
        StatLearn(x, y, 5, algorithm = AdaGrad())
        StatLearn(x, y, 5, algorithm = RDA())
        StatLearn(x, y, 5, algorithm = MMGrad())
        o = StatLearn(x, y, 5, algorithm = AdaMMGrad())

        @fact predict(o, x) --> roughly(x * o.β + o.β0)
        @fact coef(o) --> vcat(o.β0, o.β)
    end

    context(@subtitle "L1Regression") do
        y = x*β + randn(n)
        StatLearn(x, y, model = L1Regression())
    end

    context(@subtitle "LogisticRegression") do
        y = [rand(Bernoulli(1.0 / (1.0 + exp(-η)))) for η in x*β]
        StatLearn(x, y, model = LogisticRegression())
    end

    context(@subtitle "PoissonRegression") do
        y = [rand(Poisson(exp(η))) for η in x*β]
        StatLearn(x, y, model = PoissonRegression())
    end

    context(@subtitle "QuantileRegression") do
        y = x*β + randn(n)
        StatLearn(x, y, model = QuantileRegression(.7))
    end

    context(@subtitle "SVMLike") do
        y = [rand(Bernoulli(1.0 / (1.0 + exp(-η)))) for η in x*β]
        StatLearn(x, y, model = SVMLike())
    end

    context(@subtitle "HuberRegression") do
        y = x*β + randn(n)
        StatLearn(x, y, model = HuberRegression(2.))
    end
end

end #module
