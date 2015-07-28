module NormalMixTest

using OnlineStats
using Distributions
using FactCheck

facts("NormalMix") do
    context("Offline: emstart() and em()") do
        n = 10_000
        trueModel = MixtureModel(Normal, [(0, 1), (10, 5)], [.5, .5])
        x = rand(trueModel, n)
        myfit1 = OnlineStats.emstart(2, x, algorithm = :naive, tol = 1e-10)
        myfit2 = OnlineStats.emstart(2, x, algorithm = :kmeans, tol = 1e-10)
        @fact probs(myfit1) => roughly([.5, .5], .05)
        @fact probs(myfit2) => roughly([.5, .5], .05)
        diff = sort(OnlineStats.means(myfit1)) - sort(OnlineStats.means(myfit2))
        @fact diff => roughly(zeros(2), .001)
        diff = sort(OnlineStats.stds(myfit1)) - sort(OnlineStats.stds(myfit2))
        @fact diff => roughly(zeros(2), .001)
        @fact sort(OnlineStats.means(myfit1)) => roughly([0., 10.], atol = .5)
        @fact sort(OnlineStats.means(myfit2)) => roughly([0., 10.], atol = .5)
        @fact_throws OnlineStats.emstart(3, randn(100), algorithm = :blah)

        d = MixtureModel(Normal, [(0, 1), (10, 5)], [.3, .7])
        OnlineStats.em(d, rand(d, 1000), verbose = true)
        @fact cdf(d, 0.) => roughly(.3 * cdf(Normal(0,1), 0.) + .7 * cdf(Normal(10, 5), 0.))
    end

    context("Online: updatebatch!") do
        n = 100_000
        trueModel = MixtureModel(Normal, [(0, 1), (10, 5)], [.3, .7])
        x = rand(trueModel, n)
        rng = 1:100
        o = NormalMix(2, x[rng], StochasticWeighting(.8))
        while maximum(rng) + 100 <= n
            rng += 100
            updatebatch!(o, x[rng])
        end
        @fact sort(OnlineStats.means(o)) => roughly([0., 10.], .1)
        @fact sort(OnlineStats.stds(o)) => roughly([1., 5.], .1)
        @fact sort(probs(o)) => roughly([.3, .7], .1)
        @fact statenames(o) => [:dist, :nobs]
        @fact state(o) => Any[o.d, nobs(o)]
    end

    context("Online: update!") do
        n = 100_000
        trueModel = MixtureModel(Normal, [(0, 1), (10, 5)], [.3, .7])
        x = rand(trueModel, n)
        rng = 1:100
        o = NormalMix(2, x[rng], StochasticWeighting(1.))
        i = 101
        while i <= n
            update!(o, x[i])
            i += 1
        end
        @fact sort(OnlineStats.means(o)) => roughly([0., 10.], 2) "weak test"
        @fact sort(OnlineStats.stds(o)) => roughly([1., 5.], 2) "weak test"
        @fact sort(probs(o)) => roughly([.3, .7], .1)
        @fact statenames(o) => [:dist, :nobs]
        @fact state(o) => Any[o.d, nobs(o)]
        o = NormalMix(2, x[rng], StochasticWeighting(.8))
        @fact components(o) => components(o.d)
        o = NormalMix(3, 0.)
        @fact update!(o, randn()) => nothing
    end

    context("Online: other") do
        @fact typeof(NormalMix(3).d) <: MixtureModel --> true
        @fact mean(NormalMix(3)) => 0.

        x = randn(1000)
        @fact mean(NormalMix(3, x)) => roughly(mean(x))
        @fact std(NormalMix(3, x)) => roughly(std(x), .001)
    end
end

end # module
