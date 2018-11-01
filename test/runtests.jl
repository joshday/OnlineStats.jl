module OnlineStatsTests
using OnlineStats, Test, Statistics, Random, LinearAlgebra, Dates
# using Plots
O = OnlineStats
import StatsBase: countmap, fit, Histogram
import DataStructures: OrderedDict, SortedDict

const y = randn(1000)
const y2 = randn(1000)
const x = randn(1000, 5)
const x2 = randn(1000, 5)
const z = Complex.(randn(10000, 5), randn(10000, 5))
const z2 = Complex.(randn(10000, 5), randn(10000, 5))
#-----------------------------------------------------------------------# Custom Printing
@info("Custom Printing")
for stat in [
        BiasVec([1,2,3])
        Bootstrap(Mean())
        CallFun(Mean(), println)
        FastNode(5)
        FastTree(5)
        FastForest(5)
        FTSeries(Variance())
        3Mean()
        HyperLogLog(10)
        LinRegBuilder(4)
        NBClassifier(5, Float64)
        ProbMap(Int)
        P2Quantile(.5)
        Series(Mean())
        StatLearn(5)
        ]
    println("  > ", stat)
end

#-----------------------------------------------------------------------# test helpers

function test_merge(o, y1, y2, compare = ≈; kw...)
    o2 = copy(o)
    fit!(o, y1)
    fit!(o2, y2)
    merge!(o, o2)
    fit!(o2, y1)
    for (v1, v2) in zip(value(o), value(o2))
        result = compare(v1, v2; kw...)
        result || @warn("Test Merge Failure: $v1 != $v2")
        @test result
    end
    @test nobs(o) == nobs(o2) == nrows(y1) + nrows(y2)
end

function test_exact(o, y, fo, fy::Function, compare = ≈; kw...)
    fit!(o, y)
    for (v1, v2) in zip(fo(o), fy(y))
        result = compare(v1, v2; kw...)
        result || @warn("Test Exact Failure: $v1 != $v2")
        @test result
    end
    @test nobs(o) == nrows(y)
end
function test_exact(o, y, fo, fy, compare = ≈; kw...)
    fit!(o, y)
    for (v1, v2) in zip(fo(o), fy)
        result = compare(v1, v2; kw...)
        result || @warn("Test Exact Failure: $v1 != $v2")
        @test result
    end
    @test nobs(o) == nrows(y)
end

nrows(v::O.VectorOb) = length(v)
nrows(m::AbstractMatrix) = size(m, 1)
nrows(t::Tuple) = length(t[2])
nrows(y::Base.Iterators.Zip2) = length(y)


#-----------------------------------------------------------------------# utils
println("\n\n")
@info("Testing Utils")
@testset "utils" begin
    @test O._dot((1,2,3), (4,5,6)) == sum([1,2,3] .* [4,5,6])
    @test length(BiasVec((1,2,3))) == 4
    @test size(BiasVec([1,2,3])) == (4,)
    @test Base.IndexStyle(BiasVec{Float64, Vector{Float64}}) == IndexLinear()
end


println("\n\n")
@info("Testing Stats")
#-----------------------------------------------------------------------# AutoCov
@testset "AutoCov" begin
    test_exact(AutoCov(10), y, autocov, autocov(y, 0:10))
    test_exact(AutoCov(10), y, autocor, autocor(y, 0:10))
    test_exact(AutoCov(10), y, nobs, length)
end
#-----------------------------------------------------------------------# Bootstrap
@testset "Bootstrap" begin
    o = fit!(Bootstrap(Mean(), 100, [1]), y)
    @test all(value.(o.replicates) .== value(o.stat))
    @test length(confint(o)) == 2
end
#-----------------------------------------------------------------------# CallFun
@testset "CallFun" begin
    test_merge(CallFun(Mean(), x->nothing), y, y2)
    test_exact(CallFun(Mean(), x->nothing), y, value, mean)
end
#-----------------------------------------------------------------------# CountMap
@testset "CountMap" begin
    test_exact(CountMap(Int), rand(1:10, 100), nobs, length, ==)
    test_exact(CountMap(Int), rand(1:10, 100), o->sort(value(o)), x->sort(countmap(x)), ==)
    test_exact(CountMap(Int), [1,2,3,4], o->O.pdf(o,1), x->.25, ==)
    test_merge(CountMap(SortedDict{Bool, Int}()), rand(Bool, 100), rand(Bool, 100), ==)
    test_merge(CountMap(SortedDict{Bool, Int}()), trues(100), falses(100), ==)
    test_merge(CountMap(SortedDict{Int, Int}()), rand(1:4, 100), rand(5:123, 50), ==)
    test_merge(CountMap(SortedDict{Int, Int}()), rand(1:4, 100), rand(5:123, 50), ==)
    test_merge(CountMap(SortedDict{String,Int}()), rand(["A","B"], 100), rand(["A","C"], 100), ==)
    o = fit!(CountMap(Int), [1,2,3,4])
    # @test all([1,2,3,4] .∈ keys(o.value))
    @test probs(o) == fill(.25, 4)
    @test probs(o, 7:9) == zeros(3)
end
#-----------------------------------------------------------------------# CovMatrix
@testset "CovMatrix" begin
    test_exact(CovMatrix(Float64, 5), x, var, x -> var(x, dims=1))
    test_exact(CovMatrix(5), x, var, x -> var(x, dims=1))
    test_exact(CovMatrix(), x, std, x -> std(x, dims=1))
    test_exact(CovMatrix(5), x, mean, x -> mean(x, dims=1))
    test_exact(CovMatrix(), x, cor, cor)
    test_exact(CovMatrix(5), x, cov, cov)
    test_exact(CovMatrix(), x, o->cov(o; corrected=false), cov(x, dims=1, corrected=false))
    a = fit!(CovMatrix(), x)
    b = fit!(CovMatrix(), x2)
    c = merge(a, b)
    if any(isnan, value(c))
        @warn "Covariance value is NaN" a b c
    end
    test_merge(CovMatrix(), x, x2)
    # Complex values (nondeterministic failures...)
    # z = Complex.(randn(10000, 5), randn(10000, 5))
    # z2 = Complex.(randn(10000, 5), randn(10000, 5))
    # test_exact(CovMatrix(Complex{Float64}, 5), z, var, z -> var(z, dims=1))
    # test_exact(CovMatrix(Complex{Float64}, 5), z, var, z -> var(z, dims=1))
    # test_exact(CovMatrix(Complex{Float64}), z, std, z -> std(z, dims=1))
    # test_exact(CovMatrix(Complex{Float64}, 5), z, mean, z -> mean(z, dims=1))
    # test_exact(CovMatrix(Complex{Float64}), z, cor, cor)
    # test_exact(CovMatrix(Complex{Float64}, 5), z, cov, cov)
    # test_exact(CovMatrix(Complex{Float64}), z, o->cov(o; corrected=false), cov(z, dims=1, corrected=false))
    # test_merge(CovMatrix(Complex{Float64}), z, z2)
end
#-----------------------------------------------------------------------# CStat
@testset "CStat" begin
    data = y + y2 * im
    data2 = y2 + y * im
    test_exact(CStat(Mean()), data, o->value(o)[1], mean(y))
    test_exact(CStat(Mean()), data, o->value(o)[2], mean(y2))
    test_exact(CStat(Mean()), data, nobs, length, ==)
    test_merge(CStat(Mean()), y, y2)
    test_merge(CStat(Mean()), data, data2)
end
#-----------------------------------------------------------------------# Diff
@testset "Diff" begin
    test_exact(Diff(), y, value, y -> y[end] - y[end-1])
    o = fit!(Diff(Int), 1:10)
    @test diff(o) == 1
    @test last(o) == 10
end
#-----------------------------------------------------------------------# Extrema
@testset "Extrema" begin
    test_exact(Extrema(), y, extrema, extrema, ==)
    test_exact(Extrema(), y, maximum, maximum, ==)
    test_exact(Extrema(), y, minimum, minimum, ==)
    test_exact(Extrema(Int), rand(Int, 100), minimum, minimum, ==)
    test_merge(Extrema(), y, y2, ==)
end
#-----------------------------------------------------------------------# FastNode
@testset "FastNode" begin
    data = (x,rand(1:3,1000))
    data2 = (x,rand(1:3,1000))
    Y = vcat(data, data2)
    o = fit!(FastNode(5, 3), data)
    o2 = fit!(FastNode(5, 3), data2)
    merge!(o, o2)
    fit!(o2, data)
    for k in 1:3, j in 1:5
        @test value(o.stats[k][j])[1] ≈ value(o2.stats[k][j])[1]
        @test value(o.stats[k][j])[2] ≈ value(o2.stats[k][j])[2]
    end
    @test length(o[1]) == 3
    pvec = [mean(data[2] .== 1), mean(data[2] .== 2), mean(data[2] .== 3)]
    test_exact(FastNode(5, 3), data, probs, pvec)
    test_exact(FastNode(5, 3), data, nobs, 1000)
    test_exact(FastNode(5, 3), data, O.nkeys, 3)
    test_exact(FastNode(5, 3), data, O.nvars, 5)
    @test classify(o) ∈ [1, 2, 3]
end
#-----------------------------------------------------------------------# FastTree
@testset "FastTree" begin
    X, Y = O.fakedata(FastNode, 10^4, 10)
    o = fit!(FastTree(10; splitsize=100), (X,Y))
    @test classify(o, X[1,:]) ∈ [1, 2]
    @test all(0 .< classify(o, X) .< 3)
    @test O.nkeys(o) == 2
    @test O.nvars(o) == 10
    @test mean(classify(o, X) .== Y) > .5
    test_exact(FastTree(10), (X[1,:],Y[1]), length, 1)

    # Issue 116
    Random.seed!(218)
    X,Y = OnlineStats.fakedata(FastNode, 10^4, 1)
    fit!(FastTree(1, splitsize=100),(X,Y))
end
#-----------------------------------------------------------------------# FastForest
@testset "FastForest" begin
    X, Y = O.fakedata(FastNode, 10^4, 10)
    o = fit!(FastForest(10; splitsize=500, λ = .7), (X, Y))
    @test classify(o, randn(10)) in 1:2
    @test mean(classify(o, X) .== Y) > .5
end
#-----------------------------------------------------------------------# Fit[Dist]
@testset "Fit[Dist]" begin
@testset "FitBeta" begin
    test_merge(FitBeta(), rand(10), rand(10))
    @test value(FitBeta()) == (1.0, 1.0)
end
@testset "FitCauchy" begin
    test_exact(FitCauchy(), y, value, y->(0,1), atol = .5)
    test_merge(FitCauchy(), y, y2, atol = .5)
    @test value(FitCauchy()) == (0.0, 1.0)
end
@testset "FitGamma" begin
    test_merge(FitGamma(), y, y2)
    @test value(FitGamma()) == (1.0, 1.0)
end
@testset "FitLogNormal" begin
    test_merge(FitLogNormal(), exp.(y), exp.(y2))
    @test value(FitLogNormal()) == (0.0, 1.0)
end
@testset "FitNormal" begin
    test_merge(FitNormal(), y, y2)
    test_exact(FitNormal(), y, value, (mean(y), std(y)))
    test_exact(FitNormal(), y, mean, mean(y))
    test_exact(FitNormal(), y, var, var(y))
    test_exact(FitNormal(), y, std, std(y))
    @test value(FitNormal()) == (0.0, 1.0)
    # pdf and cdf
    o = fit!(FitNormal(), [-1, 0, 1])
    @test O.pdf(o, 0.0) ≈ 0.3989422804014327
    @test O.pdf(o, -1.0) ≈ 0.24197072451914337
    @test O.cdf(o, 0.0) ≈ 0.5
    @test ≈(O.cdf(o, -1.0), 0.15865525393145702; atol=.001)
end
@testset "FitMultinomial" begin
    o = FitMultinomial(5)
    @test value(o)[2] == ones(5) / 5
    data = [1 2 3 4 5; 1 2 3 4 5]
    test_exact(o, data, o->value(o)[2], collect(2:2:10) ./ sum(data))
    test_merge(FitMultinomial(3), rand(1:4, 10, 3), rand(2:7, 11, 3))
end
@testset "FitMvNormal" begin
    test_merge(FitMvNormal(2), [y y2], [y2 y])
    @test value(FitMvNormal(2)) == (zeros(2), Matrix(I, 2, 2))
end
end
#-----------------------------------------------------------------------# FTSeries
@testset "FTSeries" begin
    test_merge(FTSeries(Mean(), Variance(); transform = abs), y, y2)
    test_exact(FTSeries(Mean(); transform=abs), y, o->value(o)[1], mean(abs, y))
    data = [-1, 1, 2]
    o = fit!(FTSeries(Mean(); filter = x->x>0), data)
    @test o.nfiltered == 1
    @test nobs(o) == 2
end
#-----------------------------------------------------------------------# Group
@testset "Group" begin
    o = Group(Mean(), Mean(), Mean(), Variance(), Variance())
    @test o[1] == first(o) == Mean()
    @test o[5] == last(o) == Variance()

    test_exact(o, x, values, vcat(mean(x, dims=1)[1:3], var(x, dims=1)[4:5]))
    test_exact(5Mean(), x, values, mean(x, dims=1))
    test_exact(5Variance(), x, values, var(x, dims=1))

    o2 = Group(m1=Mean(), m2=Mean(), m3=Mean(), m4=Mean(), m5=Mean())
    test_exact(copy(o2), x, values, mean(x, dims=1))
    test_merge(o2, x, x2, (a,b) -> value(a) ≈ value(b))

    test_merge(Group(Mean(),Variance(),Sum(),Moments(),Mean()), x, x2, (a,b) -> value(a) ≈ value(b))
    test_merge(5Mean(), x, x2, (a,b) -> value(a) ≈ value(b))
    test_merge(5Variance(), x, x2, (a,b) -> value(a) ≈ value(b))
    @test 5Mean() == 5Mean()

    g = fit!(5Mean(), x)
    @test length(g) == 5
    for (i, oi) in enumerate(g)
        @test value(oi) ≈ mean(x[:, i])
    end
end
#-----------------------------------------------------------------------# Group
@testset "GroupBy" begin
    o = GroupBy{Int}(Mean())
    fit!(o, zip([1,1,2,2], 1:4))
    @test value(value(o)[1]) ≈ 1.5
    @test value(value(o)[2]) ≈ 3.5
end
#-----------------------------------------------------------------------# HeatMap
@testset "HeatMap" begin 
    test_merge(HeatMap(-5:.1:5, -5:.1:5), x[:, 1:2], x2[:, 1:2])
end

#-----------------------------------------------------------------------# Hist
@testset "Hist" begin
    test_merge(Hist(-5:.1:5), y, y2)
    @testset "Compare with StatsBase.Histogram" begin
        for edges in (-5:5, collect(-5:5), [-5, -3.5, 0, 1, 4, 5.5])
            for data in (y, -6:.75:6)
                h1 = fit(Histogram, data, edges, closed = :left)
                test_exact(Hist(edges, Number; closed=false), data, o -> o.counts, y -> h1.weights)
                h2 = fit(Histogram, data, edges, closed = :right)
                test_exact(Hist(edges, Number; left=false, closed=false), data, o -> o.counts, y -> h2.weights)
            end
        end
    end 
    test_exact(Hist(-5:.1:5), y, extrema, extrema, atol=.2)
    test_exact(Hist(-5:.1:5), y, mean, mean, atol=.2)
    test_exact(Hist(-5:.1:5), y, nobs, length)
    test_exact(Hist(-5:.1:5), y, var, var, atol=.2)
    test_merge(Hist(-5:.1:5), y, y2)
    # merge unequal bins
    r1, r2 = -5:.2:5, -5:.1:5
    @test merge!(fit!(Hist(r1), y), fit!(Hist(r2), y2)) == fit!(Hist(r1), vcat(y, y2))
    @test O.pdf(fit!(Hist(-5:.1:5), y), 0) > 0
    @test O.pdf(fit!(Hist(-5:.1:5), y), 100) == 0
end
#-----------------------------------------------------------------------# KHist
@testset "KHist" begin
    test_exact(KHist(1000), y, mean, mean)
    test_exact(KHist(1000), y, nobs, length)
    test_exact(KHist(1000), y, var, var)
    test_exact(KHist(1000), y, median, median)
    test_exact(KHist(1000), y, quantile, quantile)
    test_exact(KHist(1000), y, std, std)
    test_exact(KHist(1000), y, extrema, extrema, ==)
    test_merge(KHist(2000), y, y2)
    test_merge(KHist(1), y, y2)
    test_merge(KHist(2000, Float32), Float32.(y), Float32.(y2))

    data = randn(10_000)

    test_exact(KHist(100), data, o->O.pdf(o, -10), 0.0)
    test_exact(KHist(100), data, o->O.pdf(o,0), 0.3989422804014327, atol=.2)
    test_exact(KHist(100), data, o->O.pdf(o, 10), 0.0)

    test_exact(KHist(100), data, o->O.cdf(o,-10), 0)
    test_exact(KHist(100), data, o->O.cdf(o,0), .5, atol=.1)
    test_exact(KHist(100), data, o->O.cdf(o,10), 1)

    @test KHist(10) == KHist(10)
end

#-----------------------------------------------------------------------# HyperLogLog
@testset "HyperLogLog" begin
    test_exact(HyperLogLog(12), y, value, y->length(unique(y)), atol=50)
    test_merge(HyperLogLog(4), y, y2)
end
#-----------------------------------------------------------------------# IndexedPartition
@testset "IndexedPartition" begin
    o = IndexedPartition(Float64, Mean())
    fit!(o, [y y2])
end
#-----------------------------------------------------------------------# KMeans
@testset "KMeans" begin
    o = fit!(KMeans(5,2), x)
end
#-----------------------------------------------------------------------# LinReg
@testset "LinReg" begin
    test_exact(LinReg(), (x,y), value, x\y)
    test_merge(LinReg(), (x,y), (x2,y2))
    # ridge
    o = fit!(LinReg(), (x,y))
    @test coef(o) ≈ x \ y
    @test coef(o, .1) ≈ (x'x + 100 * I) \ x'y
    λ = rand(5)
    @test coef(o, λ) ≈ (x'x + 1000 * Diagonal(λ)) \ x'y
    @test predict(o, x) == x * o.β
    @test predict(o, x[1,:]) == dot(o.β, x[1, :])
end
@testset "LinRegBuilder" begin
    test_merge(LinRegBuilder(), [x y], [x2 y2])
    test_exact(LinRegBuilder(), [x y], o->coef(o,y=6), [x ones(length(y))] \ y)
    o = fit!(LinRegBuilder(), [y x])
    @test coef(o, .1; bias=false) ≈ (x'x + 100 * I) \ x'y
    λ = rand(5)
    @test coef(o, λ; bias=false) ≈ (x'x + 1000 * Diagonal(λ)) \ x'y
end
#-----------------------------------------------------------------------# Mean
@testset "Mean" begin
    test_exact(Mean(), y, mean, mean)
    test_merge(Mean(), y, y2)
end
#-----------------------------------------------------------------------# ML
@testset "ML" begin
    o = OnlineStats.preprocess(eachrow(x))
    for i in 1:5
        @test o.group[i] isa OnlineStats.Numerical
    end
    o = OnlineStats.preprocess(eachrow(rand(Bool, 100, 2)))
    for i in 1:2
        @test o.group[i] isa OnlineStats.Categorical
    end
    o = OnlineStats.preprocess(eachrow(rand(1:5, 100, 5)), 3=>OnlineStats.Categorical(Int))
    @test o.group[3] isa OnlineStats.Categorical
    @test o.group[1] isa OnlineStats.Numerical
end
#-----------------------------------------------------------------------# Moments
@testset "Moments" begin
    test_exact(Moments(), y, value, [mean(y), mean(y .^ 2), mean(y .^ 3), mean(y .^4) ])
    test_exact(Moments(), y, skewness, skewness, atol = .1)
    test_exact(Moments(), y, kurtosis, kurtosis, atol = .1)
    test_exact(Moments(), y, mean, mean)
    test_exact(Moments(), y, var, var)
    test_exact(Moments(), y, std, std)
    test_merge(Moments(), y, y2)
end
#-----------------------------------------------------------------------# Mosaic
@testset "Mosaic" begin
    test_merge(Mosaic(Int,Int), rand(1:5, 100, 2), rand(1:5, 100, 2), ==)
end
#-----------------------------------------------------------------------# MovingTimeWindow
@testset "MovingTimeWindow" begin
    dates = Date(2010):Day(1):Date(2011)
    data = 1:length(dates)
    o = MovingTimeWindow(Day(4); timetype=Date, valtype=Int)
    test_exact(copy(o), zip(dates, data), value, Pair.(dates[end-4:end], data[end-4:end]), ==)
    test_merge(o, zip(dates[1:2], data[1:2]), zip(dates[3:4], data[3:4]), ==)
end
#-----------------------------------------------------------------------# MovingWindow
@testset "MovingWindow" begin
    test_exact(MovingWindow(10,Int), 1:12, value, 3:12)
    for i in 1:10
        test_exact(MovingWindow(10,Int), 1:12, o -> o[i], i + 2)
    end
end
#-----------------------------------------------------------------------# NBClassifier
@testset "NBClassifier" begin
    X, Y = randn(1000, 5), rand(Bool, 1000)
    X2, Y2 = randn(1000, 5), rand(Bool, 1000)
    o = fit!(NBClassifier(5, Bool), (X,Y))
    merge!(o, fit!(NBClassifier(5, Bool), (X2,Y2)))
    @test nobs(o) == 2000
    @test length(probs(o)) == 2
    @test sum(predict(o, x[1,:])) ≈ 1
    @test classify(o, x[1, :]) || !classify(o, x[1, :])
    @test OnlineStats.nvars(o) == 5
    @test OnlineStats.nkeys(o) == 2
    @test length(o[2]) == 2
end
#-----------------------------------------------------------------------# OrderStats
@testset "OrderStats" begin
    test_merge(OrderStats(100), y, y2)
    test_exact(OrderStats(1000), y, value, sort, ==)
    test_exact(OrderStats(1000), y, quantile, quantile)
end
#-----------------------------------------------------------------------# Partition
@testset "Partition" begin
    test_exact(Partition(Mean()), y, nobs, length)
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
    test_exact(ProbMap(Float64), y, o->sort(collect(keys(o.value))), sort(y))
    # merge
    data, data2 = rand(1:4, 100), rand(1:4, 100)
    o = fit!(ProbMap(Int), data)
    o2 = fit!(ProbMap(Int), data2)
    merge!(o, o2)
    fit!(o2, data)
    @test sort(collect(keys(o.value))) == sort(collect(keys(o2.value)))
    test_exact(ProbMap(Int), [1,1,2,2,3,3,4,4], probs, fill(.25, 4))
    test_exact(ProbMap(Int), [1,1,2,2,3,3,4,4], o->probs(o, [1,2, 9]), [.5, .5, 0])
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
        test_exact(copy(o), data, value, quantile(data,τ), atol = .5)
        test_merge(copy(o), data, data2, atol = .5)
    end
    for τi in τ
        test_exact(P2Quantile(τi), data, value, quantile(data, τi), atol = .2)
    end
end
#-----------------------------------------------------------------------# ReservoirSample
@testset "ReservoirSample" begin
    test_exact(ReservoirSample(1000), y, value, identity, ==)
    # merge
    o1 = fit!(ReservoirSample(9), y)
    o2 = fit!(ReservoirSample(9), y2)
    merge!(o1, o2)
    fit!(o2, y)
    for yi in value(o1)
        @test (yi ∈ y) || (yi ∈ y2)
    end
end
#-----------------------------------------------------------------------# Series
@testset "Series" begin
    test_merge(Series(Mean(), Variance()), y, y2)
    test_merge(Series(m=Mean(), v=Variance()), y, y2)
    test_exact(Series(Mean(), Variance()), y, o->value(o)[1], mean(y))
    test_exact(Series(m=Mean(), v=Variance()), y, o->value(o)[1], mean(y))
    test_exact(Series(Mean(), Variance()), y, o->value(o)[2], var(y))
    test_exact(Series(m=Mean(), v=Variance()), y, o->value(o)[2], var(y))
end
#-----------------------------------------------------------------------# StatHistory
@testset "StatHistory" begin
    o = fit!(StatHistory(Mean(), 10), 1:20)
    @test length(o.circbuff) == 10
    for (i, m) in enumerate(reverse(o.circbuff))
        @test nobs(m) == 10 + i
    end
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
            o = fit!(StatLearn(5, A, L; rate=LearningRate(.7)), (X,Y))
            @test o.loss isa typeof(L)
            @test o.alg isa typeof(A)
            any(isnan.(o.β)) && @info((L, A))
            merge!(o, copy(o))
            @test coef(o) == o.β
            @test predict(o, X) == X * o.β
            @test ≈(coef(o), β; atol=1.5)
            @test O.objective(o, X, Y) ≈ value(o.loss, Y, predict(o, X), AggMode.Mean()) + value(o.penalty, o.β, o.λ)
        end
        for L in [LogitMarginLoss(), DWDMarginLoss(1.0)]
            print(" | $L")
            o = fit!(StatLearn(5, A, L), (X,Y2))
            @test mean(Y2 .== classify(o, X)) > .5
        end
        println()
    end
end
#-----------------------------------------------------------------------# Sum
@testset "Sum" begin
    test_exact(Sum(), y, sum, sum)
    test_exact(Sum(Int), 1:100, sum, sum)
    test_merge(Sum(), y, y2)
end
#-----------------------------------------------------------------------# Variance
@testset "Variance" begin
    test_exact(Variance(), y, mean, mean)
    test_exact(Variance(), y, std, std)
    test_exact(Variance(), y, var, var)
    test_merge(Variance(), y, y2)

    # Issue 116
    @test std(Variance()) == 1
    @test std(fit!(Variance(), 1)) == 1
    @test std(fit!(Variance(), [1, 2])) == sqrt(.5)
end

end #module
