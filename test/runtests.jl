using OnlineStats, Test, LinearAlgebra, Random, StatsBase, Statistics, Dates

#-----------------------------------------------------------------------# utils
n = 1000
x,  y,  z  = rand(Bool, n), randn(n), rand(1:10, n)
x2, y2, z2 = rand(Bool, n), randn(n), rand(1:10, n)
xs, ys, zs = vcat(x, x2), vcat(y, y2), vcat(z, z2)

p = 5
xmat,  ymat,  zmat  = rand(Bool, n, p), randn(n, p), rand(1:10, n, p)
xmat2, ymat2, zmat2 = rand(Bool, n, p), randn(n, p), rand(1:10, n, p)


function mergestats(a::OnlineStat, y1, y2)
    b = copy(a)
    fit!(a, y1)             # fit a on y1
    fit!(b, y2)             # fit b on y2
    merge!(a, b)            # merge b into a
    fit!(b, y1)             # fit b on y1
    @test nobs(a) == nobs(b) == length(y1) + length(y2)
    a, b
end
mergevals(o1::OnlineStat, y1, y2) = map(value, mergestats(o1, y1, y2))






#-----------------------------------------------------------------------# AutoCov
@testset "AutoCov" begin
    o = fit!(AutoCov(10), y)
    @test autocov(o) ≈ autocov(y, 0:10)
    @test autocor(o) ≈ autocor(y, 0:10)
    @test nobs(o) == n
end
#-----------------------------------------------------------------------# Bootstrap
@testset "Bootstrap" begin
    o = fit!(Bootstrap(Mean(), 100, [1]), y)
    @test all(value.(o.replicates) .== value(o.stat))
    c = confint(o)
    @test length(c) == 2
    @test c[1] ≤ c[2]
end
#-----------------------------------------------------------------------# CallFun
@testset "CallFun" begin
    i = 0
    o = fit!(CallFun(Mean(), x -> i+=1), y)
    @test value(o) ≈ mean(y)
    @test i == n
    @test ≈(mergevals(CallFun(Mean(), x->nothing), y, y2)...)
end
#-----------------------------------------------------------------------# CovMatrix
@testset "CovMatrix" begin
    o = fit!(CovMatrix(), eachrow(ymat))
    @test value(o) ≈ cov(ymat)
    @test cov(o) ≈ cov(ymat)
    @test cor(o) ≈ cor(ymat)
    @test all(x -> ≈(x...), zip(var(o), var(ymat; dims=1)))
    @test all(x -> ≈(x...), zip(std(o), std(ymat; dims=1)))
    @test all(x -> ≈(x...), zip(mean(o), mean(ymat; dims=1)))

    @test ≈(mergevals(CovMatrix(), OnlineStatsBase.eachrow(ymat), OnlineStatsBase.eachrow(ymat2))...)
    @test ≈(mergevals(CovMatrix(), OnlineStatsBase.eachcol(ymat'), OnlineStatsBase.eachcol(ymat2'))...)
    @test ≈(mergevals(CovMatrix(Complex{Float64}), OnlineStatsBase.eachrow(ymat * im), OnlineStatsBase.eachrow(ymat2))...)
    @test ≈(mergevals(CovMatrix(Complex{Float64}), OnlineStatsBase.eachrow(ymat * im), OnlineStatsBase.eachrow(ymat2 * im))...)
end
#-----------------------------------------------------------------------# Diff
@testset "Diff" begin
    @test value(fit!(Diff(), y)) == y[end] - y[end-1]
    o = fit!(Diff(Int), 1:10)
    @test diff(o) == 1
    @test last(o) == 10
end
#-----------------------------------------------------------------------# Fit[Dist]
@testset "Fit[Dist]" begin
    @testset "FitBeta" begin
        @test value(FitBeta()) == (1.0, 1.0)
        a, b = mergevals(FitBeta(), rand(100), rand(100))
        @test a[1] ≈ b[1]
        @test a[2] ≈ b[2]
    end
    @testset "FitCauchy" begin
        @test value(FitCauchy()) == (0.0, 1.0)
        a, b = mergevals(FitCauchy(), y, y2)
        @test ≈(a[1], b[1]; atol=.5)
        @test ≈(a[2], b[2]; atol=.5)
    end
    @testset "FitGamma" begin
        @test value(FitGamma()) == (1.0, 1.0)
        a, b = mergevals(FitGamma(), rand(100), rand(100))
        @test a[1] ≈ b[1]
        @test a[2] ≈ b[2]
    end
    @testset "FitLogNormal" begin
        @test value(FitLogNormal()) == (0.0, 1.0)
        a, b = mergevals(FitLogNormal(), exp.(y), exp.(y2))
        @test a[1] ≈ b[1]
        @test a[2] ≈ b[2]
    end
    @testset "FitNormal" begin
        @test value(FitNormal()) == (0.0, 1.0)
        a, b = mergestats(FitNormal(), y, y2)
        @test value(a)[1] ≈ value(b)[1]
        @test value(a)[2] ≈ value(b)[2]

        @test mean(a) ≈ mean(ys)
        @test var(a) ≈ var(ys)
        @test std(a) ≈ std(ys)

        # pdf and cdf
        o = fit!(FitNormal(), [-1, 0, 1])
        @test OnlineStats.pdf(o, 0.0) ≈ 0.3989422804014327
        @test OnlineStats.pdf(o, -1.0) ≈ 0.24197072451914337
        @test OnlineStats.cdf(o, 0.0) ≈ 0.5
        @test ≈(OnlineStats.cdf(o, -1.0), 0.15865525393145702; atol=.001)
    end
    @testset "FitMultinomial" begin
        o = FitMultinomial(5)
        @test value(o)[2] == ones(5) / 5
        data = [1 2 3 4 5; 1 2 3 4 5]
        @test value(fit!(o, eachrow(data)))[2] == collect(2:2:10) ./ sum(data)

        data1 = OnlineStatsBase.eachrow(rand(1:4, 10, 3))
        data2 = OnlineStatsBase.eachrow(rand(2:7, 11, 3))
        a, b = mergevals(FitMultinomial(3), data1, data2)
        @test ≈(a[2], b[2])
    end
    @testset "FitMvNormal" begin
        @test value(FitMvNormal(2)) == (zeros(2), Matrix(I, 2, 2))
        a, b = mergevals(FitMvNormal(2), OnlineStatsBase.eachrow([y y2]), OnlineStatsBase.eachrow([y2 y]))
        @test a[1] ≈ b[1]
        @test a[2] ≈ b[2]
    end
end
#-----------------------------------------------------------------------# FastNode
@testset "FastNode" begin
    X, Y = ymat, rand(1:3, 1000)
    X2, Y2 = ymat, rand(1:3, 1000)
    data  = zip(eachrow(X), Y)
    data2 = zip(eachrow(X2), Y2)
    o  = fit!(FastNode(5, 3), data)
    o2 = fit!(FastNode(5, 3), data2)
    merge!(o, o2)
    fit!(o2, data)
    for k in 1:3, j in 1:5
        @test value(o.stats[k][j])[1] ≈ value(o2.stats[k][j])[1]
        @test value(o.stats[k][j])[2] ≈ value(o2.stats[k][j])[2]
    end
    @test length(o[1]) == 3

    pvec = [mean(Y .== 1), mean(Y .== 2), mean(Y .== 3)]
    o = fit!(FastNode(5, 3), data)
    @test probs(o) == pvec
    @test nobs(o) == 1000
    @test OnlineStats.nkeys(o) == 3
    @test OnlineStats.nvars(o) == 5
    @test classify(o) ∈ [1, 2, 3]
end
#-----------------------------------------------------------------------# FastTree
@testset "FastTree" begin
    X, Y = OnlineStats.fakedata(FastNode, 10^4, 10)
    o = fit!(FastTree(10; splitsize=100), zip(eachrow(X),Y))
    @test classify(o, X[1,:]) ∈ [1, 2]
    @test all(0 .< classify(o, X) .< 3)
    @test OnlineStats.nkeys(o) == 2
    @test OnlineStats.nvars(o) == 10
    @test mean(classify(o, X) .== Y) > .5

    # Issue 116
    Random.seed!(218)
    X,Y = OnlineStats.fakedata(FastNode, 10^4, 1)
    fit!(FastTree(1, splitsize=100), zip(eachrow(X),Y))
end
#-----------------------------------------------------------------------# FastForest
@testset "FastForest" begin
    X, Y = OnlineStats.fakedata(FastNode, 10^4, 10)
    o = fit!(FastForest(10; splitsize=500, λ = .7), zip(eachrow(X), Y))
    @test classify(o, randn(10)) in 1:2
    @test mean(classify(o, X) .== Y) > .5
end

#-----------------------------------------------------------------------# HeatMap
@testset "HeatMap" begin
    data1 = OnlineStatsBase.eachrow(ymat[:, 1:2])
    data2 = OnlineStatsBase.eachrow(ymat2[:, 1:2])
    @test ==(mergevals(HeatMap(-5:.1:5, -5:.1:5), data1, data2)...)
end
#-----------------------------------------------------------------------# Hist
@testset "Hist" begin
    @test ==(mergevals(Hist(-5:.1:5), y, y2)...)
    @testset "Hist compared to StatsBase.Histogram" begin
        for edges in (-5:5, collect(-5:5), [-5, -3.5, 0, 1, 4, 5.5])
            for data in (y, -6:.75:6)
                w  = fit(Histogram, data, edges, closed = :left).weights
                w2 = fit(Histogram, data, edges, closed = :right).weights
                @test fit!(Hist(edges, Number; closed=false),             data).counts == w
                @test fit!(Hist(edges, Number; closed=false, left=false), data).counts == w2
            end
        end
    end
    o = fit!(Hist(-5:.1:5), y)
    for (v1, v2) in zip(extrema(o), extrema(y))
        @test ≈(v1, v2; atol=.1)
    end
    @test ≈(mean(o), mean(y); atol=.1)
    @test ≈(var(o), var(y); atol=.2)

    # merge unequal bins
    r1, r2 = -5:.2:5, -5:.1:5
    @test merge!(fit!(Hist(r1), y), fit!(Hist(r2), y2)) == fit!(Hist(r1), vcat(y, y2))
    @test OnlineStats.pdf(fit!(Hist(-5:.1:5), y), 0) > 0
    @test OnlineStats.pdf(fit!(Hist(-5:.1:5), y), 100) == 0
end
#-----------------------------------------------------------------------# KHist
@testset "KHist" begin
    @test KHist(10) == KHist(10)

    o = fit!(KHist(1000), y)
    @test mean(o) ≈ mean(y)
    @test var(o) ≈ var(y)
    @test median(o) ≈ median(y)
    @test quantile(o) ≈ quantile(y, [0, .25, .5, .75, 1])
    @test std(o) ≈ std(y)
    @test extrema(o) == extrema(y)

    ==(mergevals(KHist(2000), y, y2)...)
    ==(mergevals(KHist(1), y, y2)...)
    ==(mergevals(KHist(2000, Float32), Float32.(y), Float32.(y2))...)

    data = randn(10_000)
    o = fit!(KHist(50), data)
    @test OnlineStats.pdf(o, -10) == 0.0
    @test ≈(OnlineStats.pdf(o, 0.0), 0.3989422804014327, atol=.2)
    @test OnlineStats.pdf(o, 10) == 0.0
    @test OnlineStats.cdf(o, -10) == 0.0
    @test ≈(OnlineStats.cdf(o, 0.0), .5; atol=.1)
    @test OnlineStats.cdf(o, 10) == 1.0
end
#-----------------------------------------------------------------------# HyperLogLog
@testset "HyperLogLog" begin
    @test ≈(value(fit!(HyperLogLog(), y)), n; atol=20)
    @test ==(mergevals(HyperLogLog(), x, x2)...)
    @test ==(mergevals(HyperLogLog(), y, y2)...)
    @test ==(mergevals(HyperLogLog(), z, z2)...)
end
#-----------------------------------------------------------------------# IndexedPartition
@testset "IndexedPartition" begin
    o = IndexedPartition(Float64, Mean())
    fit!(o, zip(y, y2))
end
#-----------------------------------------------------------------------# KahanSum
@testset "KahanSum" begin
    @test value(fit!(KahanSum(), y)) ≈ sum(y)
    @test value(fit!(KahanSum(Int), x)) == sum(x)
    @test value(fit!(KahanSum(Int), z)) == sum(z)
    @test ≈(mergevals(KahanSum(), y, y2)...)
end
#-----------------------------------------------------------------------# KahanMean
@testset "KahanMean" begin
    @test value(fit!(KahanMean(), y)) ≈ mean(y)
    @test ≈(mergevals(KahanMean(), y, y2)...)
end
#-----------------------------------------------------------------------# KahanVariance
@testset "KahanVariance" begin
    o = fit!(KahanVariance(), y)
    @test mean(o) ≈ mean(y)
    @test var(o) ≈ var(y)
    @test std(o) ≈ std(y)
    @test ≈(mergevals(KahanVariance(), y, y2)...)

    # Issue 116
    @test std(KahanVariance()) == 1
    @test std(fit!(KahanVariance(), 1)) == 1
    @test std(fit!(KahanVariance(), [1, 2])) == sqrt(.5)
end
#-----------------------------------------------------------------------# KMeans
@testset "KMeans" begin
    o = fit!(KMeans(5,2), eachrow(ymat))
    sort!(o, rev=true)
    @test o.value[1].n ≥ o.value[2].n
end
#-----------------------------------------------------------------------# LinReg
@testset "LinReg" begin
    ≈(mergevals(LinReg(), zip(eachrow(ymat), y), zip(eachrow(ymat2), y2))...)

    o = fit!(LinReg(), zip(eachrow(ymat), y))
    @test coef(o) ≈ ymat \ y
    @test coef(o, .1) ≈ (ymat'ymat ./ n + .1I) \ ymat'y ./ n
    @test coef(o, .1:.1:.5) ≈ (ymat'ymat ./ n + Diagonal(.1:.1:.5)) \ ymat'y ./ n
    @test predict(o, ymat) == ymat * o.β
    @test predict(o, ymat[1,:]) == dot(ymat[1,:], o.β)
end
#-----------------------------------------------------------------------# LinRegBuilder
@testset "LinRegBuilder" begin
    @test ≈(mergevals(LinRegBuilder(), OnlineStatsBase.eachrow(ymat), OnlineStatsBase.eachrow(ymat2))...)

    o = fit!(LinRegBuilder(), eachrow(ymat))
    for i in 1:5
        data = ymat[:, setdiff(1:5, i)]
        @test coef(o; y=i) ≈ [data ones(n)] \ ymat[:,i]
        @test coef(o, .1; y=i, bias=false) ≈ (data'data ./ n + .1*I) \ data'ymat[:,i] ./ n
    end

    o2 = fit!(LinReg(), zip(eachrow(ymat[:,[4,1]]), ymat[:,3]))
    @test coef(o, [.2,.4]; y=3, x = [4,1], bias=false) ≈ coef(o2, [.2, .4])
end
#-----------------------------------------------------------------------# ML
@testset "ML" begin
    o = OnlineStats.preprocess(OnlineStatsBase.eachrow(ymat))
    for i in 1:5
        @test o.group[i] isa OnlineStats.Numerical
    end
    o = OnlineStats.preprocess(OnlineStatsBase.eachrow(xmat))
    for i in 1:2
        @test o.group[i] isa OnlineStats.Categorical
    end
    o = OnlineStats.preprocess(OnlineStatsBase.eachrow(zmat), 3 => OnlineStats.Categorical(Int))
    @test o.group[3] isa OnlineStats.Categorical
    @test o.group[1] isa OnlineStats.Numerical
end

#-----------------------------------------------------------------------# Mosaic
@testset "Mosaic" begin
    @test ==(mergevals(Mosaic(Int,Int), zip(z, z2), zip(z2, z))...)
end
#-----------------------------------------------------------------------# MovingTimeWindow
@testset "MovingTimeWindow" begin
    dates = Date(2010):Day(1):Date(2011)
    data = Int.(1:length(dates))
    o = fit!(MovingTimeWindow(Day(4); timetype=Date, valtype=Int), zip(dates, data))
    @test value(o) == collect(Pair(a,b) for (a,b) in zip(dates[end-4:end], data[end-4:end]))

    d1 = zip(dates[1:2], data[1:2])
    d2 = zip(dates[3:4], data[3:4])
    @test ==(mergevals(MovingTimeWindow(Day(4); timetype=Date, valtype=Int), d1, d2)...)
end
#-----------------------------------------------------------------------# MovingWindow
@testset "MovingWindow" begin
    o = fit!(MovingWindow(10, Int), 1:12)
    for i in 1:10
        @test o[i] == (1:12)[i + 2]
    end
end
#-----------------------------------------------------------------------# NBClassifier
@testset "NBClassifier" begin
    o = fit!(NBClassifier(5, Bool), zip(eachrow(ymat),x))
    merge!(o, fit!(NBClassifier(5, Bool), zip(eachrow(ymat2), x2)))
    @test nobs(o) == 2000
    @test length(probs(o)) == 2
    @test sum(predict(o, ymat[1,:])) ≈ 1
    @test classify(o, ymat[1, :]) || !classify(o, ymat[1, :])
    @test OnlineStats.nvars(o) == 5
    @test OnlineStats.nkeys(o) == 2
    @test length(o[2]) == 2
end
#-----------------------------------------------------------------------# OrderStats
@testset "OrderStats" begin
    @test ≈(mergevals(OrderStats(100), y, y2)...)
    o = fit!(OrderStats(n), y)
    @test value(o) == sort(y)
    @test quantile(o, 0:.25:1) == quantile(y, 0:.25:1)
end
#-----------------------------------------------------------------------# Partition
@testset "Partition" begin
    # merging
    o = fit!(Partition(Mean(), 1000), y)
    o2 = fit!(Partition(Mean(), 1000), y2)
    merge!(o, o2)
    fit!(o2, y)
    @test nobs(o) == nobs(o2)
    @test all(nobs.(o.parts) .== nobs.(o2.parts))
    for i in 1:5
        @test value(o.parts[i]) ≈ value(o2.parts[500 + i])
    end
end
#-----------------------------------------------------------------------# ProbMap
@testset "ProbMap" begin
    @test sort(collect(keys(fit!(ProbMap(Float64), y).value))) == sort(y)
    # merge
    data, data2 = rand(1:4, 100), rand(1:4, 100)
    o = fit!(ProbMap(Int), data)
    o2 = fit!(ProbMap(Int), data2)
    merge!(o, o2)
    fit!(o2, data)
    @test sort(collect(keys(o.value))) == sort(collect(keys(o2.value)))
    @test probs(fit!(ProbMap(Int), [1,1,2,2,3,3,4,4])) ≈ fill(.25, 4)
    @test probs(fit!(ProbMap(Int), [1,1,2,2,3,3,4,4]), [1,2,9]) ≈ [.5, .5, 0]
end
#-----------------------------------------------------------------------# Quantile
@testset "Quantile/P2Quantile" begin
    data = randn(10_000)
    data2 = randn(10_000)
    τ = .1:.1:.9
    for o in [
            Quantile(τ; alg=SGD()),
            Quantile(τ; alg=MSPI()),
            Quantile(τ; alg=OMAS()),
            Quantile(τ; alg=ADAGRAD())
            ]
        @test ≈(value(fit!(copy(o), data)), quantile(data, τ), atol=.5)
        @test ≈(mergevals(o, data, data2)...; atol=.5)

    end
    for τi in τ
        @test ≈(value(fit!(P2Quantile(τi),data)), quantile(data, τi), atol=.2)
    end
end
#-----------------------------------------------------------------------# ReservoirSample
@testset "ReservoirSample" begin
    @test value(fit!(ReservoirSample(n), y)) == y
    a, b = mergestats(ReservoirSample(9), y, y2)
    for yi in value(a)
        @test (yi ∈ y) || (yi ∈ y2)
    end
end
#-----------------------------------------------------------------------# StatLag
@testset "StatLag" begin
    o = fit!(StatLag(Mean(), 10), 1:20)
    @test length(o.lag.value) == 10
    for (i, m) in enumerate(reverse(o.lag.value))
        @test nobs(m) == 10 + i
    end
    @test nobs(value(o)[1]) == 20
end
#-----------------------------------------------------------------------# StatLearn
@testset "StatLearn" begin
    X = randn(10_000, 5)
    β = collect(-1:.5:1)
    Y = X * β + randn(10_000)
    Y2 = 2.0 .* [rand()< 1 /(1 + exp(-η)) for η in X*β] .- 1.0
    for A in [SGD(),ADAGRAD(),ADAM(),ADAMAX(),ADADELTA(),RMSPROP(),OMAS(),OMAP(),MSPI()]
        print("  > $A")
        print(": ")
        for L in [.5 * L2DistLoss()]
            print(" | $L")
            # sanity checks
            o = fit!(StatLearn(5, A, L; rate=LearningRate(.7)), zip(eachrow(X),Y))
            @test o.loss isa typeof(L)
            @test o.alg isa typeof(A)
            any(isnan.(o.β)) && @info((L, A))
            merge!(o, copy(o))
            @test coef(o) == o.β
            @test predict(o, X) == X * o.β
            @test ≈(coef(o), β; atol=1.5)
            @test OnlineStats.objective(o, X, Y) ≈ value(o.loss, Y, predict(o, X), AggMode.Mean()) + value(o.penalty, o.β, o.λ)
        end
        for L in [LogitMarginLoss(), DWDMarginLoss(1.0)]
            print(" | $L")
            o = fit!(StatLearn(5, A, L), zip(eachrow(X),Y2))
            @test mean(Y2 .== classify(o, X)) > .5
        end
        println()
    end
end
#-----------------------------------------------------------------------# Kahan

include("test_kahan.jl")

#-----------------------------------------------------------------------# Show methods
@testset "Show methods" begin
    for stat in [BiasVec([1,2,3]), Bootstrap(Mean()), CallFun(Mean(), println), FastNode(5),
                 FastTree(5), FastForest(5), FTSeries(Variance()), Group(Mean(), Mean()),
                 HyperLogLog{10}(), LinRegBuilder(4), NBClassifier(5, Float64), ProbMap(Int),
                 P2Quantile(.5), Series(Mean()), StatLearn(5)]
        println("  > ", stat)
    end
end
