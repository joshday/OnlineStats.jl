module NormalMixTest

using OnlineStats
using Distributions
using FactCheck

facts("NormalMix") do
    context("Offline ") do
        n = 10_000
        trueModel = MixtureModel(Normal, [(0, 1), (10, 5)], [.5, .5])
        x = rand(trueModel, n)
        myfit1 = OnlineStats.emstart(2, x, algorithm = :naive, tol = 1e-10)
        myfit2 = OnlineStats.emstart(2, x, algorithm = :kmeans, tol = 1e-10)
        @fact probs(myfit1) => roughly([.5, .5], .05)
        @fact probs(myfit2) => roughly([.5, .5], .05)
    end

    context("Online ") do
        # TODO
    end
end

end # module
