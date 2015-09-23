module MatrixTest

using OnlineStats, FactCheck, StatsBase

facts("Matrix Updates") do
    context("Sherman-Morrison") do
        o = ShermanMorrisonInverse(10)
        o = ShermanMorrisonInverse(randn(100,10))
        statenames(o)
        state(o)
        inv(o)
    end

    context("Cholesky") do
    end
end
end # module
