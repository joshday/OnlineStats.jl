module DistributionsTest

using TestSetup, OnlineStats, FactCheck, Distributions
srand(02082016)  # today's date...removes nondeterministic NormalMix algorithm divergence.

facts(@title "Distributions") do
    context(@subtitle "fitdistribution") do
        y = rand(Beta(), 100)
        fitdistribution(Beta, y)

        y = rand(Categorical([.2, .2, .2, .4]), 100)
        fitdistribution(Categorical, y)

        y = rand(Cauchy(), 100)
        fitdistribution(Cauchy, y)

        y = rand(Gamma(2, 6), 100)
        fitdistribution(Gamma, y)

        y = randn(100)
        fitdistribution(Normal, y)

        x = rand(10)
        y = rand(Multinomial(5, x/sum(x)), 100)'
        fitdistribution(Multinomial, y)

        y = rand(MvNormal(zeros(4), diagm(ones(4))), 100)'
        fitdistribution(MvNormal, y)
    end

    context(@subtitle "Beta") do
        y = rand(Beta(), 100)
        o = FitBeta(y)
        d = fit(Beta, y)

        @fact mean(o) --> roughly(mean(d))
        @fact var(o) --> roughly(var(d))
        @fact params(o)[1] --> roughly(params(d)[1])
        @fact params(o)[2] --> roughly(params(d)[2])
        @fact nobs(o) --> 100
    end

    context(@subtitle "Categorical") do
        y = rand(Categorical([.2, .2, .2, .4]), 1000)
        o = FitCategorical(y)
        @fact ncategories(o) --> 4

        y = rand(Bool, 1000)
        o = FitCategorical(y)
        @fact ncategories(o) --> 2

        y = rand([:a, :b, :c, :d, :e, :f, :g], 1000)
        o = FitCategorical(y)
        @fact ncategories(o) --> 7
    end

    context(@subtitle "Cauchy") do
        y = rand(Cauchy(), 10000)
        o = FitCauchy(y, LearningRate())
        fit!(o, y)
        @fact params(o)[1] --> roughly(0.0, .1)
        @fact params(o)[2] --> roughly(1.0, .1)
        @fact nobs(o) --> 2 * 10000
    end

    context(@subtitle "Gamma") do
        y = rand(Gamma(2, 6), 100)
        o = FitGamma(y)
        @fact mean(o) --> roughly(mean(y))
    end

    context(@subtitle "LogNormal") do
        y = rand(LogNormal(), 100)
        o = FitLogNormal(y)
        @fact mean(o) --> roughly(mean(y), .5)
    end

    context(@subtitle "Normal") do
        y = randn(100)
        o = FitNormal(y)
        @fact mean(o) --> roughly(mean(y))
        @fact std(o) --> roughly(std(y))
        @fact var(o) --> roughly(var(y))
    end

    context(@subtitle "Multinomial") do
        x = rand(10)
        y = rand(Multinomial(5, x/sum(x)), 100)'
        o = FitMultinomial(y)
        @fact mean(o) --> roughly(vec(mean(y, 1)))
        @fact nobs(o) --> 100
    end

    context(@subtitle "MvNormal") do
        y = rand(MvNormal(zeros(4), diagm(ones(4))), 100)'
        o = FitMvNormal(y)
        @fact mean(o) --> roughly(vec(mean(y, 1)))
        @fact var(o) --> roughly(vec(var(y, 1)))
        @fact std(o) --> roughly(vec(std(y, 1)))
        @fact cov(o) --> roughly(cov(y))
        @fact nobs(o) --> 100
    end

    context(@subtitle "NormalMix") do
        d = MixtureModel(Normal, [(0,1), (2,3), (4,5)])
        y = rand(d, 50_000)
        o = NormalMix(y, 3)

        fit!(o, y)
        fit!(o, y, 10)
        @fact mean(o) --> roughly(mean(y), .5)
        @fact var(o) --> roughly(var(y), 5)
        @fact std(o) --> roughly(std(y), .5)
        @fact length(componentwise_pdf(o, 0.5)) --> 3
        @fact ncomponents(o) --> 3
        @fact typeof(component(o, 1)) == Normal --> true
        @fact length(probs(o)) --> 3
        @fact pdf(o, randn()) > 0 --> true
        @fact 0 < cdf(o, randn()) < 1 --> true
        @fact value(o) --> o.value
        @fact quantile(o, [.25, .5, .75]) --> roughly(quantile(y, [.25, .5, .75]), 2.)
        quantile(o, collect(.01:.01:.99))

        fit!(o, y, 1)
        fit!(o, y, 2)
        fit!(o, y, 5)
    end
end

end#module
