println()
println()
info("Testing Stats:")
#-----------------------------------------------------------------------# AutoCov
@testset "AutoCov" begin 
    test_exact(AutoCov(10), y, autocov, x -> autocov(x, 0:10))
    test_exact(AutoCov(10), y, autocor, x -> autocor(x, 0:10))
    test_exact(AutoCov(10), y, nobs, length)
end
#-----------------------------------------------------------------------# Bootstrap 
@testset "Bootstrap" begin 
    o = Bootstrap(Mean(), 100, [1])
    Series(y, o)
    @test all(value.(o.replicates) .== value(o))
    @test length(confint(o)) == 2
end
#-----------------------------------------------------------------------# Count 
@testset "Count" begin 
    test_exact(Count(), randn(100), value, length)
    test_merge(Count(), rand(100), rand(100), ==)
end
#-----------------------------------------------------------------------# CountMap
@testset "CountMap" begin
    test_exact(CountMap(Int), rand(1:10, 100), nobs, length, ==)
    test_exact(CountMap(Int), rand(1:10, 100), value, countmap, ==)
    test_merge(CountMap(Bool), rand(Bool, 100), rand(Bool, 100), ==)
    test_merge(CountMap(Bool), trues(100), falses(100), ==)
    test_merge(CountMap(Int), rand(1:4, 100), rand(5:123, 50), ==)
    s = Series([1,2,3,4], CountMap(Int))
    @test all([1,2,3,4] .∈ keys(s.stats[1]))
    @test probs(s.stats[1]) == fill(.25, 4)
    @test probs(s.stats[1], 7:9) == zeros(3)
end
#-----------------------------------------------------------------------# CovMatrix
@testset "CovMatrix" begin 
    test_exact(CovMatrix(5), x, var, x -> vec(var(x, 1)))
    test_exact(CovMatrix(5), x, std, x -> vec(std(x, 1)))
    test_exact(CovMatrix(5), x, mean, x -> vec(mean(x, 1)))
    test_exact(CovMatrix(5), x, cor, cor)
    test_exact(CovMatrix(5), x, cov, cov)
    test_exact(CovMatrix(5), x, o->cov(o;corrected=false), x->cov(x,1,false))
    test_merge(CovMatrix(5), x, x2)
end
#-----------------------------------------------------------------------# CStat 
@testset "CStat" begin 
    data = y + y2 * im 
    data2 = y2 + y * im
    test_exact(CStat(Mean()), data, o->value(o)[1], x -> mean(y))
    test_merge(CStat(Mean()), y, y2)
    test_merge(CStat(Mean()), data, data2)
end
#-----------------------------------------------------------------------# Diff 
@testset "Diff" begin 
    test_exact(Diff(), y, value, y -> y[end] - y[end-1])
    o = Diff(Int)
    Series(1:10, o)
    @test diff(o) == 1
    @test last(o) == 10
end
#-----------------------------------------------------------------------# Extrema
@testset "Extrema" begin 
    test_exact(Extrema(), y, extrema, extrema, ==)
    test_exact(Extrema(), y, maximum, maximum, ==)
    test_exact(Extrema(), y, minimum, minimum, ==)
    test_merge(Extrema(), y, y2, ==)
end
#-----------------------------------------------------------------------# Distributions
@testset "Fit[Distribution]" begin
    @testset "sanity check" begin
        value(Series(rand(100), FitBeta()))
        value(Series(randn(100), FitCauchy()))
        value(Series(rand(100) + 5, FitGamma()))
        value(Series(rand(100) + 5, FitLogNormal()))
        value(Series(randn(100), FitNormal()))
    end
    @testset "FitBeta" begin
        o = FitBeta()
        @test value(o) == (1.0, 1.0)
        Series(rand(200), o)
        @test value(o)[1] ≈ 1.0 atol=.4
        @test value(o)[2] ≈ 1.0 atol=.4
        test_exact(FitBeta(), rand(500), value, x->[1,1], (a,b) -> ≈(a,b;atol=.3))
        test_merge(FitBeta(), rand(50), rand(50))
    end
    @testset "FitCauchy" begin
        o = FitCauchy()
        @test value(o) == (0.0, 1.0)
        Series(randn(100), o)
        @test value(o) != (0.0, 1.0)
        merge!(o, FitCauchy(), .5)
    end
    @testset "FitGamma" begin
        o = FitGamma()
        @test value(o) == (1.0, 1.0)
        Series(rand(100) + 5, o)
        @test value(o)[1] > 0
        @test value(o)[2] > 0
        test_merge(FitGamma(), rand(100) + 5, rand(100) + 5)
    end
    @testset "FitLogNormal" begin
        o = FitLogNormal()
        @test value(o) == (0.0, 1.0)
        Series(exp.(randn(100)), o)
        @test value(o)[1] != 0
        @test value(o)[2] > 0
        test_merge(FitLogNormal(), exp.(randn(100)), exp.(randn(100)))
    end
    @testset "FitNormal" begin
        o = FitNormal()
        @test value(o) == (0.0, 1.0)
        Series(y, o)
        @test value(o)[1] ≈ mean(y)
        @test value(o)[2] ≈ std(y)
        test_merge(FitNormal(), randn(100), randn(100))
    end
    @testset "FitMultinomial" begin
        o = FitMultinomial(5)
        @test value(o)[2] == ones(5) / 5
        s = Series([1,2,3,4,5], o)
        fit!(s, [1, 2, 3, 4, 5])
        @test value(o)[2] == [1, 2, 3, 4, 5] ./ 15
        test_merge(FitMultinomial(3), [1,2,3], [2,3,4])
    end
    @testset "FitMvNormal" begin
        data = randn(1000, 3)
        o = FitMvNormal(3)
        @test value(o) == (zeros(3), eye(3))
        @test length(o) == 3
        s = Series(data, o)
        @test value(o)[1] ≈ vec(mean(data, 1))
        @test value(o)[2] ≈ cov(data)
        test_merge(FitMvNormal(3), randn(10,3), randn(10,3))
    end
end
#-----------------------------------------------------------------------# Group 
@testset "Group" begin 
    o = Group(Mean(), Mean(), Mean(), Variance(), Variance())
    test_exact(o, x, value, x -> vcat(mean(x,1)[1:3], var(x,1)[4:5]))
    test_merge([Mean() Variance() Sum() Moments() Mean()], x, x2)
end
#-----------------------------------------------------------------------# Hist 
@testset "Hist" begin
    #### KnownBins
    test_exact(Hist(-5:5), y, o -> value(o)[2], y -> fit(Histogram, y, -5:5, closed=:left).weights)
    test_exact(Hist(-5:.1:5), y, extrema, extrema, (a,b)->≈(a,b;atol=.2))
    test_exact(Hist(-5:.1:5), y, mean, mean, (a,b)->≈(a,b;atol=.2))
    test_exact(Hist(-5:.1:5), y, nobs, length)
    test_exact(Hist(-5:.1:5), y, var, var, (a,b)->≈(a,b;atol=.2))
    test_merge(Hist(-5:.1:5), y, y2)
    # merge with different edges
    o, o2 = Hist(-6:6), Hist(-6:.1:6)
    Series(y, o, o2)
    c = copy(value(o)[2])
    merge!(o, o2, .5)
    @test all(value(o)[2] .== 2c)
    @test OnlineStats.discretized_pdf(o, 0.0) > .1
    @test OnlineStats.discretized_pdf(o, -10) == 0
    @test OnlineStats.discretized_pdf(o, 10) == 0
    #### AdaptiveBins
    test_exact(Hist(100), y, mean, mean)
    test_exact(Hist(100), y, nobs, length)
    test_exact(Hist(100), y, var, var)
    test_exact(Hist(100), y, median, median)
    test_exact(Hist(100), y, quantile, quantile)
    test_exact(Hist(100), y, std, std)
    test_exact(Hist(100), y, extrema, extrema, ==)
    test_merge(Hist(200), y, y2)
    test_merge(Hist(1), y, y2)
    s = Series(y, Hist(5))
    @test OnlineStats.discretized_pdf(stats(s)[1], 0.0) > .2
    @test OnlineStats.discretized_pdf(o, -10) == 0
    @test OnlineStats.discretized_pdf(o, 10) == 0
end
#-----------------------------------------------------------------------# HyperLogLog 
@testset "HyperLogLog" begin 
    test_exact(HyperLogLog(12), y, value, y->length(unique(y)), (a,b) -> ≈(a,b;atol=3))
    test_merge(HyperLogLog(4), y, y2)
end
#-----------------------------------------------------------------------# IndexedPartition 
@testset "IndexedPartition" begin 
    test_exact(IndexedPartition(Float64, Mean()), [y y2], o -> value(merge(o)), x->mean(y2))
    o = IndexedPartition(Int, Mean())
    @test value(o) == []
    fit!(o, (1, 1.0))
    @test value(o) == [1.0]
    # merge 
    o, o2 = IndexedPartition(Float64, Mean()), IndexedPartition(Float64, Mean())
    s, s2 = Series([y y2], o), Series([y y2], o2)
    merge!(s, s2)
    @test value(merge(o)) ≈ value(merge(o2))
    # merge 2
    o, o2 = IndexedPartition(Float64, Mean()), IndexedPartition(Float64, Mean())
    s, s2 = Series([y y2], o), Series([y y2], o2)
    merge!(s, s2)
end
#-----------------------------------------------------------------------# KMeans
@testset "KMeans" begin 
    s = Series(x, KMeans(5, 2))
    @test size(value(s)[1]) == (5, 2)
    # means: [0, 0] and [10, 10]
    data = 10rand(Bool, 1000) .+ randn(1000, 2)
    o = KMeans(2, 2)
    Series(LearningRate(.9), data, o)
    m1, m2 = value(o)[:, 1], value(o)[:, 2]
    @test ≈(m1, [0, 0]; atol=.5) || ≈(m2, [0, 0]; atol=.5)
    @test ≈(m1, [10, 10]; atol=.5) || ≈(m2, [10, 10]; atol=.5)
end
#-----------------------------------------------------------------------# LinReg 
@testset "LinReg" begin 
    test_exact(LinReg(5), (x,y), coef, xy -> xy[1]\xy[2])
    test_exact(LinReg(5), (x,y), nobs, xy -> length(xy[2]))
    βridge = inv(x'x/100 + .1I) * x'y/100
    test_exact(LinReg(5, .1), (x,y), coef, x -> βridge)
    test_merge(LinReg(5), (x,y), (x2,y2))
    test_merge(LinReg(5, .1), (x,y), (x2,y2))
    # predict
    o = LinReg(5)
    Series((x,y), o)
    @test predict(o, x, Rows()) == x * o.β
    @test predict(o, x', Cols()) ≈ x * o.β
    @test predict(o, x[1,:]) == x[1,:]' * o.β
end
#-----------------------------------------------------------------------# LinRegBuilder 
@testset "LinRegBuilder" begin 
    test_exact(LinRegBuilder(6), [x y], o -> coef(o;bias=false,y=6), f -> x\y)
    test_merge(LinRegBuilder(5), x, x2)
end
#-----------------------------------------------------------------------# Mean 
@testset "Mean" begin 
    test_exact(Mean(), y, mean, mean)
    test_merge(Mean(), y, y2)
end
#-----------------------------------------------------------------------# Moments
@testset "Moments" begin 
    test_exact(Moments(), y, value, x ->[mean(x), mean(x .^ 2), mean(x .^ 3), mean(x .^4) ])
    test_exact(Moments(), y, skewness, skewness, (a,b) -> ≈(a,b,atol=.1))
    test_exact(Moments(), y, kurtosis, kurtosis, (a,b) -> ≈(a,b,atol=.1))
    test_exact(Moments(), y, mean, mean)
    test_exact(Moments(), y, var, var)
    test_exact(Moments(), y, std, std)
    test_merge(Moments(), y, y2)
end
#-----------------------------------------------------------------------# MV 
@testset "MV" begin 
    o = MV(5, Mean())
    @test length(o) == 5
    test_exact(5Mean(), x, value, x->vec(mean(x,1)))
    test_merge(5Mean(), x, x2)
    test_exact(5Variance(), x, value, x->vec(var(x,1)))
    test_merge(5Variance(), x, x2)
    @test 4Mean() == 4Mean()
end
#-----------------------------------------------------------------------# NBClassifier
@testset "NBClassifier" begin 
    n, p = 10000, 5
    X = randn(n, p)
    Y = X * linspace(-1, 1, p) .> 0
    o = NBClassifier(p, Bool, 100)
    Series((X, Y), o)
    @test predict(o, [0,0,0,0,1])[2] > .5
    @test classify(o, [0,0,0,0,1])
    X2 = [zeros(5) zeros(5) zeros(5) rand(5) 1 .+ rand(5)]
    @test all(predict(o, X2)[:, end] .> .5)
    @test all(classify(o, X2))
    @test all(predict(o, X2', Cols())[end, :] .> .5)
    @test all(classify(o, X2', Cols()))
end
#-----------------------------------------------------------------------# OrderStats 
@testset "OrderStats" begin 
    test_exact(OrderStats(100), y, value, sort)
    test_exact(OrderStats(100), y, quantile, quantile)
    test_merge(OrderStats(10), y, y2, (a,b) -> ≈(a,b;atol=.1))  # Why does this need atol?
    test_exact(OrderStats(100, Int), rand(1:10, 100), value, sort)
end
#-----------------------------------------------------------------------# Partition 
@testset "Partition" begin 
    @testset "Part" begin 
        o = OnlineStats.Part(Mean(), 1, 1)
        @test first(o) == 1 
        @test last(o) == 1
        @test value(o) == 1
        @test o < OnlineStats.Part(Mean(), 2, 1)
        @test_throws Exception fit!(o, 5, 1)
        fit!(o, 1, 3)
        @test value(o) ≈ 2
    end
    # merge(o)
    test_exact(Partition(Mean(),7), y, o -> value(merge(o)), mean)
    test_exact(Partition(Variance(),8), y, o -> value(merge(o)), var)
    # number of parts stays between b and 2b
    o = Partition(Mean(), 15)
    @test value(o) == []
    for i in 1:10
        fit!(o, y)
        @test 15 ≤ length(o.parts) ≤ 30
    end
    # merge(o, o2)
    data, data2 = randn(1000), randn(1234)
    o = Partition(Mean())
    o2 = Partition(Mean())
    s = merge!(Series(data, o), Series(data2, o2))
    @test value(merge(o)) ≈ mean(vcat(data, data2))
end
#-----------------------------------------------------------------------# Quantile
@testset "Quantile/PQuantile" begin 
    data = randn(10_000)
    data2 = randn(10_000)
    τ = .1:.1:.9
    for o in [
            Quantile(τ, SGD()), 
            Quantile(τ, MSPI()), 
            Quantile(τ, OMAS()),
            Quantile(τ, ADAGRAD())
            ]
        test_exact(o, data, value, x -> quantile(x,τ), (a,b) -> ≈(a,b,atol=.25))
        test_merge(o, data, data2, (a,b) -> ≈(a,b,atol=.25))
    end
    for τi in τ
        test_exact(PQuantile(τi), data, value, x->quantile(x, τi), (a,b) -> ≈(a,b;atol=.3))
    end
    @test_throws Exception Quantile(τ, ADAM())
end
#-----------------------------------------------------------------------# ReservoirSample
@testset "ReservoirSample" begin 
    test_exact(ReservoirSample(100), y, value, identity, ==)
    o = ReservoirSample(10)
    fit!(o, y)
    for val in o.value 
        @test val in y
    end
end
#-----------------------------------------------------------------------# StatLearn
@testset "StatLearn" begin
    n, p = 1000, 10
    X = randn(n, p)
    Y = X * linspace(-1, 1, p) + .5 * randn(n)

    for u in [SGD(), NSGD(), ADAGRAD(), ADADELTA(), RMSPROP(), ADAM(), ADAMAX(), NADAM(), 
              MSPI(), OMAP(), OMAS()]
        o = @inferred StatLearn(p, .5 * L2DistLoss(), L2Penalty(), fill(.1, p), u)
        s = @inferred Series(o)
        @test value(o, X, Y) == value(.5 * L2DistLoss(), Y, zeros(Y), AvgMode.Mean())
        fit!(s, (X, Y))
        @test nobs(s) == n
        @test coef(o) == o.β
        @test predict(o, X) == X * o.β
        @test predict(o, X', Cols()) ≈ X * o.β
        @test predict(o, X[1,:]) == X[1,:]'o.β
        @test loss(o, X, Y) == value(o.loss, Y, predict(o, X), AvgMode.Mean())

        # sanity check for merge!
        merge!(StatLearn(4, u), StatLearn(4, u), .5)

        o = StatLearn(p, LogitMarginLoss())
        o.β[:] = ones(p)
        @test classify(o, X) == sign.(vec(sum(X, 2)))

        os = OnlineStats.statlearnpath(o, 0:.01:.1)
        @test length(os) == length(0:.01:.1)

        @testset "Type stability with arbitrary argument order" begin
            l, r, v = L2DistLoss(), L2Penalty(), fill(.1, p)
            @inferred StatLearn(p, l, r, v, u)
            @inferred StatLearn(p, l, r, u, v)
            @inferred StatLearn(p, l, v, r, u)
            @inferred StatLearn(p, l, v, u, r)
            @inferred StatLearn(p, l, u, v, r)
            @inferred StatLearn(p, l, u, r, v)
            @inferred StatLearn(p, l, r, v)
            @inferred StatLearn(p, l, r, u)
            @inferred StatLearn(p, l, v, r)
            @inferred StatLearn(p, l, v, u)
            @inferred StatLearn(p, l, u, v)
            @inferred StatLearn(p, l, u, r)
            @inferred StatLearn(p, l, r)
            @inferred StatLearn(p, l, r)
            @inferred StatLearn(p, l, v)
            @inferred StatLearn(p, l, v)
            @inferred StatLearn(p, l, u)
            @inferred StatLearn(p, l, u)
            @inferred StatLearn(p, l)
            @inferred StatLearn(p, r)
            @inferred StatLearn(p, v)
            @inferred StatLearn(p, u)
            @inferred StatLearn(p)
        end
        fit!(o, (randn(p), randn()))
    end
    @testset "MM-based" begin
        X, Y = randn(100, 5), randn(100)
        @test_throws ErrorException Series((X,Y), StatLearn(5, PoissonLoss(), OMAS()))
    end
end
#-----------------------------------------------------------------------# Sum 
@testset "Sum" begin 
    test_exact(Sum(), y, sum, sum)
    test_exact(Sum(Int), 1:100, sum, sum)
end
#-----------------------------------------------------------------------# Variance 
@testset "Variance" begin 
    test_exact(Variance(), y, mean, mean)
    test_exact(Variance(), y, std, std)
    test_exact(Variance(), y, var, var)
    test_merge(Variance(), y, y2)
end