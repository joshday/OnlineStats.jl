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
        df = tracedata(QuantileMM(), 5, rand(100))
        @fact vec(OnlineStats.makenice(df[1])[1,:]) => df[1][1]
    end

    context("Weighting") do
        @fact OnlineStats.default(Weighting) => EqualWeighting()
        @fact OnlineStats.smooth(1, 3, .5) => 2
        x = ones(10)
        @fact OnlineStats.addgradient!(x, ones(10), .5) => nothing
        @fact x => ones(10) * 1.5
        w = ExponentialWeighting(10_000)
        @fact OnlineStats.weight(w, 100, 1) => 1 / 101
        o = Mean()
        @fact OnlineStats.adjusted_nobs(1, w) => 1
        @fact OnlineStats.adjusted_nobs(o) => 0
        @fact OnlineStats.adjusted_nobs(1, EqualWeighting()) => 1
    end

    context("Show OnlineStat") do
        x = rand(100)
        o = Mean(x)
        show(o)
        print(o)
        @fact OnlineStats.name(o) => string(typeof(o))
        print(Mean())
        print(Variance())
        print(Variance[Variance(), Variance()])
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
        @fact cdf(o, -1) => 0.
        @fact cdf(o, 0) => 1.
        @fact cdf(o, .5) => 1.
        @fact logcdf(o, 0) => 0.
        @fact ccdf(o, 0) => 0.
        @fact logccdf(o, -1) => 0.
        @fact quantile(o, 0) => 0.
        @fact cquantile(o, 1) => 0.
        @fact invlogcdf(o, -1) => 0.
        @fact invlogccdf(o, -1) => 0.
        @fact rand(o) => 0
        x = ones(Int, 5)
        @fact rand!(o, x) => zeros(Int, 5)
        @fact rand(o, 5) => zeros(Int, 5)
        @fact rand(o, (10, 10)) => zeros(Int, 10, 10)

        o = FitGamma()
        @fact scale(o) => 1.
        @fact shape(o) => 1.
        @fact rate(o) => 1.

        o = FitMultinomial()
        @fact ncategories(o) => 2
        @fact ntrials(o) => 1
    end
end # facts
end # module
