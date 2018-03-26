module OnlineStatsTests
using Compat, Compat.Test, Compat.LinearAlgebra, OnlineStats
O = OnlineStats
import StatsBase: countmap, fit, Histogram
import DataStructures: OrderedDict, SortedDict

#-----------------------------------------------------------------------# Custom Printing 
info("Custom Printing")
for stat in [
        BiasVec([1,2,3])
        Bootstrap(Mean())
        CallFun(Mean(), info)
        FastNode(5)
        FastTree(5)
        FTSeries(Variance())
        3Mean()
        Hist(10)
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

#-----------------------------------------------------------------------# test utils
const y = randn(1000)
const y2 = randn(1000)
const x = randn(1000, 5)
const x2 = randn(1000, 5)


function test_merge(o, y1, y2, compare = ≈; kw...)
    o2 = copy(o)
    fit!(o, y1)
    fit!(o2, y2)
    merge!(o, o2)
    fit!(o2, y1)
    for (v1, v2) in zip(value(o), value(o2))
        result = compare(v1, v2; kw...)
        result || Compat.@warn("Test Merge Failure: $v1 != $v2")
        @test result
    end
    @test nobs(o) == nobs(o2) == nrows(y1) + nrows(y2)
end

function test_exact(o, y, fo, fy::Function, compare = ≈; kw...)
    fit!(o, y)
    for (v1, v2) in zip(fo(o), fy(y))
        result = compare(v1, v2; kw...)
        result || Compat.@warn("Test Exact Failure: $v1 != $v2")
        @test result
    end
    @test nobs(o) == nrows(y)
end
function test_exact(o, y, fo, fy, compare = ≈; kw...)
    fit!(o, y)
    for (v1, v2) in zip(fo(o), fy)
        result = compare(v1, v2; kw...)
        result || Compat.@warn("Test Exact Failure: $v1 != $v2")
        @test result
    end
    @test nobs(o) == nrows(y)
end

nrows(v::O.VectorOb) = length(v)
nrows(m::AbstractMatrix) = size(m, 1)
nrows(t::Tuple) = length(t[2])


#-----------------------------------------------------------------------# utils 
@testset "utils" begin 
    @test O._dot((1,2,3), (4,5,6)) == sum([1,2,3] .* [4,5,6])
    @test length(BiasVec((1,2,3))) == 4
    @test size(BiasVec([1,2,3])) == (4,)
    for (j, xj) in enumerate(eachcol(x))
        @test xj == x[:, j]
    end
    for (i, xi) in enumerate(eachrow(x))
        @test xi == x[i, :]
    end
end


println("\n\n")
Compat.@info("Testing Stats")
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
# #-----------------------------------------------------------------------# Count 
# @testset "Count" begin 
#     test_exact(Count(), y, value, length)
#     test_merge(Count(), y, y2, ==)
# end
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
    @test all([1,2,3,4] .∈ keys(o.value))
    @test probs(o) == fill(.25, 4)
    @test probs(o, 7:9) == zeros(3)
end
#-----------------------------------------------------------------------# CovMatrix
@testset "CovMatrix" begin 
    test_exact(CovMatrix(5), x, var, x -> var(x, 1))
    test_exact(CovMatrix(), x, std, x -> std(x, 1))
    test_exact(CovMatrix(5), x, mean, x -> mean(x, 1))
    test_exact(CovMatrix(), x, cor, cor)
    test_exact(CovMatrix(5), x, cov, cov)
    test_exact(CovMatrix(), x, o->cov(o;corrected=false), cov(x, 1, false))
    test_merge(CovMatrix(), x, x2)
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
    X = randn(10^4, 10)
    Y = [rand() < 1 / (1 + exp(-η)) for η in X*(1:10)] .+ 1
    o = fit!(FastTree(10; splitsize=100), (X,Y))
    @test classify(o, X[1,:]) ∈ [1, 2]
    @test all(0 .< classify(o, X) .< 3)
    @test O.nkeys(o) == 2 
    @test O.nvars(o) == 10
end
#-----------------------------------------------------------------------# FastForest 
# @testset "FastForest" begin 
#     X = randn(10^4, 10)
#     Y = [rand() < 1 / (1 + exp(-η)) for η in X*(1:10)] .+ 1
#     o = fit!(FastForest(10; splitsize = 100), (X,Y))
# end
#-----------------------------------------------------------------------# Fit[Dist]
@testset "Fit[Dist]" begin 
@testset "FitBeta" begin 
    test_merge(FitBeta(), rand(10), rand(10))
    @test value(FitBeta()) == (1.0, 1.0)
end
# @testset "FitCauchy" begin 
#     test_exact(FitCauchy(), y, value, y->(0,1), atol = .5)
# end 
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
    @test O.cdf(o, -1.0) ≈ 0.15865525393145702
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
    @test value(FitMvNormal(2)) == (zeros(2), eye(2))
end
end
#-----------------------------------------------------------------------# FTSeries 
@testset "FTSeries" begin 
    test_merge(FTSeries(Mean(), Variance(); transform = abs), y, y2, (a,b)->≈(value(a),value(b)))
    test_exact(FTSeries(Mean(); transform=abs), y, o->value(o.stats[1]), mean(abs, y))
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

    test_exact(o, x, values, vcat(mean(x, 1)[1:3], var(x, 1)[4:5]))
    test_exact(5Mean(), x, values, mean(x, 1))
    test_exact(5Variance(), x, values, var(x, 1))

    test_merge([Mean() Variance() Sum() Moments() Mean()], x, x2, (a,b) -> all(value.(a) .≈ value.(b)))
    test_merge(5Mean(), x, x2, (a,b) -> all(value.(a) .≈ value.(b)))
    test_merge(5Variance(), x, x2, (a,b) -> all(value.(a) .≈ value.(b)))
    @test 5Mean() == 5Mean()

    g = fit!(5Mean(), x)
    @test length(g) == 5
    for (i, oi) in enumerate(g) 
        @test value(oi) ≈ mean(x[:, i])
    end
end
#-----------------------------------------------------------------------# Hist 
@testset "Hist" begin 
@testset "FixedBins" begin
    test_merge(Hist(-5:.1:5), y, y2)
    for edges in (-5:5, collect(-5:5), [-5, -3.5, 0, 1, 4, 5.5])
        for data in (y, -6:0.75:6)
            h1 = fit(Histogram, data, edges, closed = :left).weights
            test_exact(Hist(edges), data, o -> O.counts(o), y -> h1)

            h2 = fit(Histogram, data, edges, closed = :right).weights
            test_exact(Hist(edges; closed = :right), data, o -> O.counts(o), y -> h2)
        end
    end
    test_exact(Hist(-5:.1:5), y, extrema, extrema, atol=.2)
    test_exact(Hist(-5:.1:5), y, mean, mean, atol=.2)
    test_exact(Hist(-5:.1:5), y, nobs, length)
    test_exact(Hist(-5:.1:5), y, var, var, atol=.2)
    test_merge(Hist(-5:.1:5), y, y2)
end 
@testset "AdaptiveBins" begin 
    test_exact(Hist(1000), y, mean, mean)
    test_exact(Hist(1000), y, nobs, length)
    test_exact(Hist(1000), y, var, var)
    test_exact(Hist(1000), y, median, median)
    test_exact(Hist(1000), y, quantile, quantile)
    test_exact(Hist(1000), y, std, std)
    test_exact(Hist(1000), y, extrema, extrema, ==)
    test_merge(Hist(2000), y, y2)
    test_merge(Hist(1), y, y2)
    test_merge(Hist(2000, Float32), Float32.(y), Float32.(y2))
    test_merge(Hist(Float32, 2000), Float32.(y), Float32.(y2))

    data = randn(10_000)
    test_exact(Hist(100), data, o->O.pdf(o,0), 0.3989422804014327, atol=.2)
    test_exact(Hist(100), data, o->O.cdf(o,0), .5, atol=.1)
end
end
#-----------------------------------------------------------------------# HyperLogLog 
@testset "HyperLogLog" begin 
    test_exact(HyperLogLog(12), y, value, y->length(unique(y)), atol=50)
    test_merge(HyperLogLog(4), y, y2)
end
@testset "KMeans" begin 
    o = fit!(KMeans(5,2), x)
end
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
end
#-----------------------------------------------------------------------# OrderStats
@testset "OrderStats" begin 
    test_merge(OrderStats(100), y, y2)
    test_exact(OrderStats(1000), y, value, sort, ==)
    test_exact(OrderStats(1000), y, quantile, quantile)
end
#-----------------------------------------------------------------------# Partition 
@testset "Partition" begin 

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
    test_merge(Series(Mean(), Variance()), y, y2, (a,b) -> ≈(value(a), value(b)))
    test_exact(Series(Mean(), Variance()), y, o->value(o.stats[1]), mean(y))
    test_exact(Series(Mean(), Variance()), y, o->value(o.stats[2]), var(y))
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
            any(isnan.(o.β)) && info((L, A))
            merge!(o, copy(o))
            @test coef(o) == o.β
            @test predict(o, X) == X * o.β
            @test ≈(coef(o), β; atol=1.5)
            @test O.objective(o, X, Y) ≈ value(o.loss, Y, predict(o, X), AvgMode.Mean()) + value(o.penalty, o.β, o.λ)
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
end

end #module