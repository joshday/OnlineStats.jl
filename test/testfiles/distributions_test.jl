module DistributionsTest

using TestSetup, OnlineStats, FactCheck, Distributions

facts(@title "FitDistribution / FitMvDistribution") do
    context(@subtitle "Beta") do
        y = rand(Beta(), 100)
        o = FitDistribution(Beta, y)
        d = fit(Beta, y)

        @fact mean(o) --> roughly(mean(d))
        @fact var(o) --> roughly(var(d))
        @fact params(o)[1] --> roughly(params(d)[1])
        @fact params(o)[2] --> roughly(params(d)[2])
    end

    context(@subtitle "Categorical") do
        y = rand(Categorical([.2, .2, .2, .4]), 1000)
        o = FitDistribution(Categorical, y)
        @fact ncategories(o) --> 4
        @fact length(o.vec) --> 4
    end

    context(@subtitle "Cauchy") do
        y = rand(Cauchy(), 10000)
        o = FitDistribution(Cauchy, y, LearningRate())
        fit!(o, y, 5)
        @fact params(o)[1] --> roughly(0.0, .1)
        @fact params(o)[2] --> roughly(1.0, .1)
    end

    context(@subtitle "Exponential") do
        y = rand(Exponential(10), 100)
        o = FitDistribution(Exponential, y)
        @fact mean(o) --> roughly(mean(y))
    end

    context(@subtitle "Gamma") do
        y = rand(Gamma(2, 6), 100)
        o = FitDistribution(Gamma, y)
        @fact mean(o) --> roughly(mean(y))
    end

    context(@subtitle "LogNormal") do
        y = rand(LogNormal(), 100)
        o = FitDistribution(LogNormal, y)
        @fact mean(o) --> roughly(mean(y), .5)
    end

    context(@subtitle "Normal") do
        y = randn(100)
        o = FitDistribution(Normal, y)
        @fact mean(o) --> roughly(mean(y))
        @fact std(o) --> roughly(std(y))
        @fact var(o) --> roughly(var(y))
    end

    context(@subtitle "Multinomial") do
        x = rand(10)
        y = rand(Multinomial(5, x/sum(x)), 100)'
        o = FitMvDistribution(Multinomial, y)
        @fact mean(o) --> roughly(vec(mean(y, 1)))
    end

    context(@subtitle "MvNormal") do
        y = rand(MvNormal(zeros(4), diagm(ones(4))), 100)'
        o = FitMvDistribution(MvNormal, y)
        @fact mean(o) --> roughly(vec(mean(y, 1)))
        @fact var(o) --> roughly(vec(var(y, 1)))
        @fact std(o) --> roughly(vec(std(y, 1)))
        @fact cov(o) --> roughly(cov(y))
    end

    context(@subtitle "Poisson") do
        y = rand(Poisson(5), 100)
        o = FitDistribution(Poisson, y)
        @fact mean(o) --> roughly(mean(y))
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
        @fact quantile(o, [.25, .5, .75]) --> roughly(quantile(y, [.25, .5, .75]), .5)
        quantile(o, collect(.01:.01:.99))
    end
end

end#module
