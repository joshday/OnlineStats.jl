module BootstrapTest

using OnlineStats, FactCheck, StatsBase

facts("Bootstrap") do
    context("BernoulliBootstrap") do
        o = OnlineStats.Mean()
        o = OnlineStats.BernoulliBootstrap(o, 1000, .05)
        OnlineStats.update!(o, rand(10000))
        OnlineStats.cached_state(o)
        mean(o)
        std(o)
        var(o)
        confint(o)
    end
end

end #module
