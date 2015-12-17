module StreamStatsTest

using TestSetup, OnlineStats, FactCheck, StatsBase

x = randn(500)
x1 = randn(500)
x2 = randn(501)
xs = hcat(x1, x)

facts(@title "Bootstrap") do
    context(@subtitle "BernoulliBootstrap") do
        o = Mean()
        o = BernoulliBootstrap(o, mean, 1000)
        fit!(o, rand(10000))
        cached_state(o)
        mean(o)
        std(o)
        var(o)
        confint(o)
        confint(o, .95, :normal)
        @fact_throws confint(o, .95, :fakemethod)
        replicates(o)
    end

    context(@subtitle "PoissonBootstrap") do
        o = Mean()
        o = PoissonBootstrap(o, mean, 1000)
        fit!(o, rand(10000))
        cached_state(o)
        mean(o)
        std(o)
        var(o)
        confint(o)
        replicates(o)
    end

    context(@subtitle "FrozenBootstrap") do
        o = Mean()
        o = BernoulliBootstrap(o, mean, 1000)

        o2 = Mean()
        o2 = BernoulliBootstrap(o2, mean, 1000)
        fit!(o, randn(1000))
        fit!(o2, randn(1000) + 3)

        d = o - o2
        mean(d)
        var(d)
        std(d)
        confint(d)
        replicates(o)
    end
end

end
