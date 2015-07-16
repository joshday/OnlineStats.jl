module BootstrapTest

using OnlineStats, FactCheck, StatsBase

facts("Bootstrap") do
    context("BernoulliBootstrap") do
        o = OnlineStats.Mean()
        o = OnlineStats.BernoulliBootstrap(o, 1000)
        OnlineStats.update!(o, rand(10000))
        OnlineStats.cached_state(o)
        mean(o)
        std(o)
        var(o)
        confint(o)
    end
    context("PoissonBootstrap") do
        o = OnlineStats.Mean()
        o = OnlineStats.PoissonBootstrap(o, 1000)
        OnlineStats.update!(o, rand(10000))
        OnlineStats.cached_state(o)
        mean(o)
        std(o)
        var(o)
        confint(o)
    end
    context("FrozenBootstrap") do
        o = OnlineStats.Mean()
        o = OnlineStats.BernoulliBootstrap(o, 1000)

        o2 = OnlineStats.Mean()
        o2 = OnlineStats.BernoulliBootstrap(o2, 1000)
        update!(o, randn(1000))
        update!(o2, randn(1000) + 3)

        d = o - o2
        mean(d)
        var(d)
        std(d)
        confint(d)
    end
end

end #module
