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

        df = tracedata(Mean(), 5, rand(100))
        @fact OnlineStats.getnice(df, :μ) => convert(Array, df[1])
        @fact OnlineStats.makenice(df[1]) => convert(Array, df[1])
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
        print(Mean())
        print(Variance())

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

        o = FitBernoulli()
        @fact succprob(o) => 0.0
        @fact failprob(o) => 1.0
        for i in 0:10
            @fact mgf(o, i) => 1.0
            @fact cf(o, i) => 1.0
        end
        @fact insupport(o, .5) => false
        @fact pdf(o, 0) => 1.0
        @fact logpdf(o, 0) => 0.0
        @fact loglikelihood(o, zeros(Int, 10)) => 0.0
    end
end # facts
end # module
