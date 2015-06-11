module CommonTest

using OnlineStats, FactCheck, Distributions, DataFrames

facts("Common") do
    context("Helper Functions") do
        n, p = rand(20:100, 2)
        x = rand(n, p)
        @fact OnlineStats.row(x, 1) => vec(x[1, :])
        @fact OnlineStats.col(x, 1) => vec(x[:, 1])
        @fact OnlineStats.row(x, n) => vec(x[n, :])
        @fact OnlineStats.col(x, p) => vec(x[:, p])

        OnlineStats.row!(x, 1, ones(p))
        OnlineStats.row!(x, n, ones(p))
        @fact OnlineStats.row(x, 1) => OnlineStats.row(x, n)
        @fact OnlineStats.row(x, n) => ones(p)

        OnlineStats.col!(x, 1, ones(n))
        OnlineStats.col!(x, p, ones(n))
        @fact OnlineStats.col(x, 1) => OnlineStats.col(x, p)
        @fact OnlineStats.col(x, p) => ones(n)

        x = rand(10)
        @fact OnlineStats.mystring(x) => string(x)
        @fact OnlineStats.mystring(x[1]) => @sprintf("%f", x[1])

    end

    context("Weighting") do
        @fact OnlineStats.default(Weighting) => EqualWeighting()
        @fact OnlineStats.smooth(1, 3, .5) => 2
    end

    context("Show OnlineStat") do
        x = rand(100)
        o = Mean(x)
        show(o)
        print(o)
        @fact OnlineStats.name(o) => string(typeof(o))
    end

    context("Show DistributionStat") do
        x1 = randn(100)
        o = onlinefit(Normal, x1)
        show(o)

        @fact params(o) => params(o.d)
        @fact mean(o) => mean(o.d)
        @fact var(o) => var(o.d)
        @fact std(o) => std(o.d)
        @fact median(o) => median(o.d)
        @fact mode(o) => mode(o.d)
        @fact modes(o) => modes(o.d)
        @fact skewness(o) => skewness(o.d)
        @fact kurtosis(o) => kurtosis(o.d)
        @fact isplatykurtic(o) => isplatykurtic(o.d)
        @fact ismesokurtic(o) => ismesokurtic(o.d)
        @fact entropy(o) => entropy(o.d)
    end
end # facts
end # module
