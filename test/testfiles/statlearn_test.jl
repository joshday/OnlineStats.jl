module StatLearnTest

using TestSetup, OnlineStats, Distributions, FactCheck
import OnlineStats: _j


function linearmodeldata(n, p, corr = 0)
    # linear model data with correlated predictors
    V = zeros(p, p)
    for j in 1:p, i in 1:p
        V[i, j] = corr^abs(i - j)
    end
    x = rand(MvNormal(ones(p), V), n)'
    β = vcat(1.:5, zeros(p-5))
    y = x*β + randn(n)
    (β, x, y)
end




facts(@title "StatLearn") do
    n, p = 500, 5
    x = randn(n, p)
    β = collect(linspace(-1, 1, p))
    β_with_intercept = vcat(0.0, β)
    xβ = x*β

    alg = [SGD(), AdaGrad(), AdaGrad2(), AdaDelta(), RDA(), MMGrad()]
    pen = [NoPenalty(), RidgePenalty(.1), LassoPenalty(.1), ElasticNetPenalty(.1, .5)]
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
            StatLearn(x, y, m, a, p)
            StatLearn(x, y, 10, m, a, p)
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
        o = StatLearn(x, y, L2Regression())
        @fact loss(o, x, y) --> roughly(.5 * mean(abs2(y - predict(o, x))))

        y = generate(L1Regression(), xβ)
        o = StatLearn(x, y, L1Regression())
        @fact loss(o, x, y) --> roughly(mean(abs(y - predict(o, x))))

        y = generate(LogisticRegression(), xβ)
        o = StatLearn(x, y, LogisticRegression())
        η = o.β0 + x * o.β
        l = mean([-y[i] * η[i] + log(1.0 + exp(η[i])) for i in 1:length(η)])
        @fact loss(o, x, y) --> roughly(l)

        y = generate(PoissonRegression(), xβ)
        o = StatLearn(x, y, PoissonRegression(), RDA())
        η = o.β0 + x * o.β
        @fact loss(o, x, y) --> roughly(mean(-y .* η + exp(η)))

        y = generate(QuantileRegression(), xβ)
        o = StatLearn(x, y, QuantileRegression())
        r = y - o.β0 - x * o.β
        @fact loss(o, x, y) --> roughly(mean([r[i] * (o.model.τ - (r[i]<0)) for i in 1:n]))

        y = generate(SVMLike(), xβ)
        o = StatLearn(x, y, SVMLike())
        η = o.β0 + x * o.β
        @fact loss(o, x, y) --> roughly(mean([max(0.0, 1.0 - y[i] * η[i]) for i in 1:n]))

        y = generate(HuberRegression(), xβ)
        o = StatLearn(x, y, HuberRegression())
        δ = o.model.δ
        r = y - o.β0 - x * o.β
        v = [abs(r[i]) < δ? 0.5 * r[i]^2 : δ * (abs(r[i]) - 0.5 * δ) for i in 1:n]
        @fact loss(o, x, y) --> roughly(mean(v))
    end

    # context(@subtitle "StatLearnSparse") do
    #     n, p = 100000, 10
    #     x = randn(n, p)
    #     β = collect(1.:p) - p/2
    #     y = x * β + randn(n)
    #     o = StatLearn(p)
    #     sp = StatLearnSparse(o, HardThreshold(burnin = 100))
    #     sp = StatLearnSparse(o)
    #     fit!(sp, x, y)
    #     fit!(sp, x, y)
    #     @fact coef(sp) --> coef(o)
    #     @fact value(sp) --> value(o)
    #     @fact nobs(sp) --> nobs(o)
    # end
    #
    # context(@subtitle "StatLearnCV") do
    #     n, p, rho = 10000, 10, .5
    #     β, x, y = linearmodeldata(n, p, rho)
    #     _, xtest, ytest = linearmodeldata(500, p, rho)
    #
    #     o = StatLearn(p, penalty = LassoPenalty(1.), algorithm = RDA())
    #     cv = StatLearnCV(o, xtest, ytest, 1234)
    #     o2 = StatLearn(p, algorithm = RDA())
    #
    #     fit!(cv, x, y)
    #     fit!(o2, x, y)
    #     @fact loss(o2, x, y) --> less_than(loss(o, x, y))
    #
    #     o = StatLearn(p)
    #     cv = StatLearnCV(o, xtest, ytest, 1000)
    #     fit!(cv, x, y)
    #     @fact nobs(o) --> length(y)
    #     @fact value(cv) --> value(o)
    #     @fact coef(cv) --> coef(o)
    #     @fact predict(cv, x) --> predict(o, x)
    #     @fact loss(cv, x, y) --> loss(o, x, y)
    #     @fact loss(cv) --> loss(o, xtest, ytest)
    # end
end

end #module
