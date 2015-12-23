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

    context(@subtitle "loss") do
        y = generate(L2Regression(), xβ)
        o = StatLearn(x, y, model = L2Regression())
        @fact loss(o, x, y) --> roughly(mean(abs2(y - predict(o, x))))

        y = generate(L1Regression(), xβ)
        o = StatLearn(x, y, model = L1Regression())
        @fact loss(o, x, y) --> roughly(mean(abs(y - predict(o, x))))

        y = generate(LogisticRegression(), xβ)
        o = StatLearn(x, y, model = LogisticRegression())
        η = o.β0 + x * o.β
        l = mean([-y[i] * η[i] + log(1.0 + exp(η[i])) for i in 1:length(η)])
        @fact loss(o, x, y) --> roughly(l)

        y = generate(PoissonRegression(), xβ)
        o = StatLearn(x, y, model = PoissonRegression(), algorithm = RDA())
        η = o.β0 + x * o.β
        @fact loss(o, x, y) --> roughly(mean(-y .* η + exp(η)))

        y = generate(QuantileRegression(), xβ)
        o = StatLearn(x, y, model = QuantileRegression())
        r = y - o.β0 - x * o.β
        @fact loss(o, x, y) --> roughly(mean([r[i] * (o.model.τ - (r[i]<0)) for i in 1:n]))

        y = generate(SVMLike(), xβ)
        o = StatLearn(x, y, model = SVMLike())
        η = o.β0 + x * o.β
        @fact loss(o, x, y) --> roughly(mean([max(0.0, 1.0 - y[i] * η[i]) for i in 1:n]))

        y = generate(HuberRegression(), xβ)
        o = StatLearn(x, y, model = HuberRegression())
        δ = o.model.δ
        r = y - o.β0 - x * o.β
        v = [abs(r[i]) < δ? 0.5 * r[i]^2 : δ * (abs(r[i]) - 0.5 * δ) for i in 1:n]
        @fact loss(o, x, y) --> roughly(mean(v))
    end

    context(@subtitle "StatLearnSparse") do
        n, p = 100000, 10
        x = randn(n, p)
        β = collect(1.:p) - p/2
        y = x * β + randn(n)
        o = StatLearn(p)
        sp = StatLearnSparse(o, HardThreshold(burnin = 100))
        fit!(sp, x, y)
        fit!(sp, x, y, 100)
        @fact coef(sp) --> coef(o)
        @fact value(sp) --> value(o)
        @fact nobs(sp) --> nobs(o)
    end

    context(@subtitle "StatLearnCV") do
        n, p = 10000, 10
        x = randn(n, p)
        xtest = randn(500, p)
        β = collect(1.:p) - p/2
        y = x*β + randn(n)
        ytest = xtest*β + randn(500)

        o = StatLearn(p)
        cv = StatLearnCV(o, xtest, ytest)
        fit!(cv, x, y)

        o = StatLearn(p, penalty = L2Penalty(), λ = 1)
        cv = StatLearnCV(o, xtest, ytest)
        fit!(cv, x, y)
        display(cv)
    end
end

end #module
