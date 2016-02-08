module StreamStatsTest

using TestSetup, OnlineStats, FactCheck, StatsBase

x = randn(500)
x1 = randn(500)
x2 = randn(501)
xs = hcat(x1, x)
facts(@title "HyperLogLog") do
    o = HyperLogLog(5)
    y = rand(Bool, 10000)
    for yi in y
        fit!(o, yi)
    end
    @fact value(o) --> roughly(2, .5)
end


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
        fit!(o, rand(1000))
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
        fit!(o, randn(100))
        fit!(o2, randn(100) + 3)

        d = o - o2
        mean(d)
        var(d)
        std(d)
        confint(d)
        replicates(o)
    end
end

end
