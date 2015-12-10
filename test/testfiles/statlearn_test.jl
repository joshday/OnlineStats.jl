module StatLearnTest

using TestSetup, OnlineStats, Distributions, FactCheck
import OnlineStats: _j

facts(@title "StatLearn") do
    n, p = 500, 5
    x = randn(n, p)
    β = collect(linspace(-1, 1, p))
    xβ = x*β

    alg = [SGD(), AdaGrad(), RDA(), MMGrad(), AdaMMGrad()]
    pen = [NoPenalty(), L2Penalty(), L1Penalty(), ElasticNetPenalty()]
    mod = [
        L2Regression(), L1Regression(), LogisticRegression(),
        PoissonRegression(), QuantileRegression(), SVMLike(), HuberRegression()
    ]

    generate(::L2Regression, xβ) = xβ + randn(size(xβ, 1))
    generate(::L1Regression, xβ) = xβ + randn(size(xβ, 1))
    generate(::LogisticRegression, xβ) = [rand(Bernoulli(1 / (1 + exp(-η)))) for η in xβ]
    generate(::PoissonRegression, xβ) = [rand(Poisson(exp(η))) for η in xβ]
    generate(::QuantileRegression, xβ) = xβ + randn(size(xβ, 1))
    generate(::SVMLike, xβ) = [rand(Bernoulli(1 / (1 + exp(-η)))) for η in xβ]
    generate(::HuberRegression, xβ) = xβ + randn(size(xβ, 1))

    context(@subtitle "Full Factorial of Combinations") do
        for a in alg, p in pen, m in mod
            y = generate(m, xβ)
            println("          > $a, $p, $m")
            StatLearn(x, y, model = m, algorithm = a, penalty = p)
            StatLearn(x, y, 10, model = m, algorithm = a, penalty = p)
        end
    end


    context(@subtitle "methods") do
        y = x*β + randn(n)
        o = StatLearn(x, y)
        @fact predict(o, x) --> roughly(x * o.β + o.β0)
        @fact coef(o) --> vcat(o.β0, o.β)
    end
end

end #module
