module CommonTest

using OnlineStats, FactCheck, Distributions, ArrayViews

facts("Common") do
    context("Show and print methods") do
        print_with_color(:blue, "Output here is messy for the sake of getting coverage for show and print\n")
        x = rand(100)
        o = Mean(x)
        update_call!(o, mean, x)
        show(o); print(o); print([o, o]);
        @fact OnlineStats.name(o) --> string(typeof(o))
        b = BernoulliBootstrap(o, mean)
        show(b)

        x1 = randn(100)
        o = distributionfit(Normal, x1)
        show(o);
        show(NoPenalty())
        show(L1Penalty(.1))
        show(L2Penalty(.1))
        show(ElasticNetPenalty(.1, .5))
        show(SCADPenalty(.1, 4))

        # StochasticModel stuff
        show(StochasticModel(10))

        show(RDA())
        show(MMGrad())
        show(ProxGrad())
        show(SGD())

        show(L1Regression())
        show(L2Regression())
        show(LogisticRegression())
        show(PoissonRegression())
        show(QuantileRegression(.6))
        show(SVMLike())
        show(HuberRegression(2.))

        show(StochasticModel(5))
        show(StochasticModel(5, intercept = false))
        show(StochasticModelCV(randn(100,5), randn(100), randn(100,5), randn(100)))
    end

    context("Helper Functions") do
        n, p = rand(20:100, 2)
        x = rand(n, p)
        @fact OnlineStats.row(x, 1) --> vec(x[1, :])
        @fact OnlineStats.col(x, 1) --> vec(x[:, 1])
        @fact OnlineStats.row(x, n) --> vec(x[n, :])
        @fact OnlineStats.col(x, p) --> vec(x[:, p])
        @fact OnlineStats.nrows(x) --> size(x, 1)
        @fact OnlineStats.ncols(x) --> size(x, 2)

        OnlineStats.row!(x, 1, ones(p))
        OnlineStats.row!(x, n, ones(p))
        @fact OnlineStats.row(x, 1) --> OnlineStats.row(x, n)
        @fact OnlineStats.row(x, n) --> ones(p)
        @fact OnlineStats.rows([1,2,3], 2) --> 2
        @fact OnlineStats.rows(x, 1) --> vec(x[1, :])

        OnlineStats.col!(x, 1, ones(n))
        OnlineStats.col!(x, p, ones(n))
        @fact OnlineStats.col(x, 1) --> OnlineStats.col(x, p)
        @fact OnlineStats.col(x, p) --> ones(n)
        @fact OnlineStats.cols(x, 1) --> OnlineStats.col(x, 1)
        @fact OnlineStats.cols(x, 1:2) --> view(x, :, 1:2)

        x = rand(10)
        @fact OnlineStats.mystring(x) --> string(x)
        @fact OnlineStats.mystring(x[1]) --> @sprintf("%f", x[1])
        @fact OnlineStats.row(x, 1) --> x[1]
    end

    context("Weighting") do
        @fact OnlineStats.default(Weighting) --> EqualWeighting()
        @fact OnlineStats.smooth(1, 3, .5) --> 2
        x = ones(10)
        @fact OnlineStats.addgradient!(x, ones(10), .5) --> nothing
        @fact x --> ones(10) * 1.5
        w = ExponentialWeighting(10_000)
        @fact OnlineStats.weight(w, 100, 1) --> 1 / 101
        o = Mean()
        @fact OnlineStats.adjusted_nobs(1, w) --> 1
        @fact OnlineStats.adjusted_nobs(o) --> 0
        @fact OnlineStats.adjusted_nobs(1, EqualWeighting()) --> 1
    end


    context("Show DistributionStat") do
        x1 = randn(100)
        o = distributionfit(Normal, x1)

        @fact params(o) --> params(o.d)
        @fact mean(o) --> mean(o.d)
        @fact var(o) --> var(o.d)
        @fact std(o) --> std(o.d)
        @fact median(o) --> median(o.d)
        @fact mode(o) --> mode(o.d)
        @fact modes(o) --> modes(o.d)
        @fact skewness(o) --> skewness(o.d)
        @fact kurtosis(o) --> kurtosis(o.d)
        @fact isplatykurtic(o) --> isplatykurtic(o.d)
        @fact ismesokurtic(o) --> ismesokurtic(o.d)
        @fact entropy(o) --> entropy(o.d)

        o = FitBernoulli()
        @fact succprob(o) --> 0.0
        @fact failprob(o) --> 1.0
        for i in 0:10
            @fact mgf(o, i) --> 1.0
            @fact cf(o, i) --> 1.0
        end
        @fact insupport(o, .5) --> false
        @fact pdf(o, 0) --> 1.0
        @fact logpdf(o, 0) --> 0.0
        @fact loglikelihood(o, zeros(Int, 10)) --> 0.0
        @fact cdf(o, -1) --> 0.
        @fact cdf(o, 0) --> 1.
        @fact cdf(o, .5) --> 1.
        @fact logcdf(o, 0) --> 0.
        @fact ccdf(o, 0) --> 0.
        @fact logccdf(o, -1) --> 0.
        @fact quantile(o, 0) --> 0.
        @fact cquantile(o, 1) --> 0.
        @fact invlogcdf(o, -1) --> 0.
        @fact invlogccdf(o, -1) --> 0.
        @fact rand(o) --> 0
        x = ones(Int, 5)
        @fact rand!(o, x) --> zeros(Int, 5)
        @fact rand(o, 5) --> zeros(Int, 5)
        @fact rand(o, (10, 10)) --> zeros(Int, 10, 10)

        o = FitGamma()
        @fact scale(o) --> 1.
        @fact shape(o) --> 1.
        @fact rate(o) --> 1.

        o = FitMultinomial()
        @fact ncategories(o) --> 2
        @fact ntrials(o) --> 1
    end

    context("Bias") do
        x = rand(10)
        bv = BiasVector(x)
        @fact length(bv) --> length(x) + 1
        @fact size(bv) --> (length(x)+1,)
        @fact bv[1] --> x[1]
        @fact bv[10] --> x[10]
        @fact bv[11] --> 1.0
        bv[4] = 100.0
        @fact x[4] --> 100.0
        # @fact x[10:11] --> vcat(x[10],1.0)  #doesnt work
        @fact_throws (x[11] = 0.0)
        @fact_throws x[12]
        @fact_throws x[0]

        x = rand(10,10)
        bm = BiasMatrix(x)
        @fact length(bm) --> length(x) + size(x,1)
        @fact size(bm) --> (size(x,1),size(x,2)+1)
        @fact bm[1,1] --> x[1,1]
        @fact bm[10,1] --> x[10,1]
        @fact bm[1,11] --> 1.0
        bm[4,6] = 100.0
        @fact x[4,6] --> 100.0
        # @fact x[10,10:11] --> hcat(x[10,10], 1.0)  #doesnt work
        @fact_throws (x[10,11] = 0.0)

    end
end # facts
end # module
