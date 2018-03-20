using Compat, Compat.Test, OnlineStats
O = OnlineStats
import StatsBase: countmap, fit, Histogram
import DataStructures: OrderedDict, SortedDict

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

function test_exact(o, y, fo, fy, compare = ≈; kw...)
    fit!(o, y)
    for (v1, v2) in zip(fo(o), fy(y))
        result = compare(v1, v2; kw...)
        result || Compat.@warn("Test Exact Failure: $v1 != $v2")
        @test result
    end
    @test nobs(o) == nrows(y)
end

nrows(v::Vector) = length(v)
nrows(m::Matrix) = size(m, 1)
nrows(t::Tuple) = length(t[2])

println("\n\n")
Compat.@info("Testing Stats")
# #-----------------------------------------------------------------------# AutoCov
# @testset "AutoCov" begin 
#     test_exact(AutoCov(10), y, autocov, x -> autocov(x, 0:10))
#     test_exact(AutoCov(10), y, autocor, x -> autocor(x, 0:10))
#     test_exact(AutoCov(10), y, nobs, length)
# end
# #-----------------------------------------------------------------------# Bootstrap 
# @testset "Bootstrap" begin 
#     o = fit!(Bootstrap(Mean(), 100, [1]), y)
#     @test all(value.(o.replicates) .== value(o.stat))
#     @test length(confint(o)) == 2
# end
# #-----------------------------------------------------------------------# CallFun
# @testset "CallFun" begin
#     test_merge(CallFun(Mean(), x->nothing), y, y2)
#     test_exact(CallFun(Mean(), x->nothing), y, value, mean)
# end
# #-----------------------------------------------------------------------# Count 
# @testset "Count" begin 
#     test_exact(Count(), y, value, length)
#     test_merge(Count(), y, y2, ==)
# end
# #-----------------------------------------------------------------------# CountMap
# @testset "CountMap" begin
#     test_exact(CountMap(Int), rand(1:10, 100), nobs, length, ==)
#     test_exact(CountMap(Int), rand(1:10, 100), o->sort(value(o)), x->sort(countmap(x)), ==)
#     test_exact(CountMap(Int), [1,2,3,4], o->O.pdf(o,1), x->.25, ==)
#     test_merge(CountMap(SortedDict{Bool, Int}()), rand(Bool, 100), rand(Bool, 100), ==)
#     test_merge(CountMap(SortedDict{Bool, Int}()), trues(100), falses(100), ==)
#     test_merge(CountMap(SortedDict{Int, Int}()), rand(1:4, 100), rand(5:123, 50), ==)
#     test_merge(CountMap(SortedDict{Int, Int}()), rand(1:4, 100), rand(5:123, 50), ==)
#     o = fit!(CountMap(Int), [1,2,3,4])
#     @test all([1,2,3,4] .∈ keys(o.value))
#     @test probs(o) == fill(.25, 4)
#     @test probs(o, 7:9) == zeros(3)
# end
# #-----------------------------------------------------------------------# CovMatrix
# @testset "CovMatrix" begin 
#     test_exact(CovMatrix(5), x, var, x -> var(x, 1))
#     test_exact(CovMatrix(), x, std, x -> std(x, 1))
#     test_exact(CovMatrix(5), x, mean, x -> mean(x, 1))
#     test_exact(CovMatrix(), x, cor, cor)
#     test_exact(CovMatrix(5), x, cov, cov)
#     test_exact(CovMatrix(), x, o->cov(o;corrected=false), x->cov(x, 1, false))
#     test_merge(CovMatrix(), x, x2)
# end
# #-----------------------------------------------------------------------# CStat 
# @testset "CStat" begin 
#     data = y + y2 * im 
#     data2 = y2 + y * im
#     test_exact(CStat(Mean()), data, o->value(o)[1], x -> mean(y))
#     test_exact(CStat(Mean()), data, o->value(o)[2], x -> mean(y2))
#     test_exact(CStat(Mean()), data, nobs, length, ==)
#     test_merge(CStat(Mean()), y, y2)
#     test_merge(CStat(Mean()), data, data2)
# end
# #-----------------------------------------------------------------------# Diff 
# @testset "Diff" begin 
#     test_exact(Diff(), y, value, y -> y[end] - y[end-1])
#     o = fit!(Diff(Int), 1:10)
#     @test diff(o) == 1
#     @test last(o) == 10
# end
# #-----------------------------------------------------------------------# Extrema
# @testset "Extrema" begin 
#     test_exact(Extrema(), y, extrema, extrema, ==)
#     test_exact(Extrema(), y, maximum, maximum, ==)
#     test_exact(Extrema(), y, minimum, minimum, ==)
#     test_exact(Extrema(Int), rand(Int, 100), minimum, minimum, ==)
#     test_merge(Extrema(), y, y2, ==)
# end
# #-----------------------------------------------------------------------# Fit[Dist]
# @testset "Fit[Dist]" begin 
# @testset "FitBeta" begin 
#     test_merge(FitBeta(), rand(10), rand(10))
# end
# @testset "FitCauchy" begin 
#     test_exact(FitCauchy(), y, value, y->(0,1), atol = .5)
# end 
# @testset "FitGamma" begin 
#     test_merge(FitGamma(), y, y2)
# end
# @testset "FitLogNormal" begin 
#     test_merge(FitLogNormal(), exp.(y), exp.(y2))
# end
# @testset "FitNormal" begin 
#     test_merge(FitNormal(), y, y2)
#     test_exact(FitNormal(), y, value, y->(mean(y), std(y)))
# end
# @testset "FitMultinomial" begin 
# end
# @testset "FitMvNormal" begin 
#     test_merge(FitMvNormal(2), [y y2], [y2 y])
# end
# end
# @testset "FastNode" begin 
#     data = (x,rand(1:3,1000))
#     data2 = (x,rand(1:3,1000))
#     o = fit!(FastNode(5, 3), data)
#     o2 = fit!(FastNode(5, 3), data2)
#     merge!(o, o2)
#     fit!(o2, data)
#     @test value(o.stats[1][1])[1] ≈ value(o2.stats[1][1])[1]
#     @test value(o.stats[1][1])[2] ≈ value(o2.stats[1][1])[2]
# end
# #-----------------------------------------------------------------------# Group 
# @testset "Group" begin 
#     o = Group(Mean(), Mean(), Mean(), Variance(), Variance())
#     @test o[1] == first(o) == Mean()
#     @test o[5] == last(o) == Variance()

#     test_exact(o, x, values, x -> vcat(mean(x, 1)[1:3], var(x, 1)[4:5]))
#     test_exact(5Mean(), x, values, x->mean(x, 1))
#     test_exact(5Variance(), x, values, x->var(x, 1))

#     test_merge([Mean() Variance() Sum() Moments() Mean()], x, x2, (a,b) -> all(value.(a) .≈ value.(b)))
#     test_merge(5Mean(), x, x2, (a,b) -> all(value.(a) .≈ value.(b)))
#     test_merge(5Variance(), x, x2, (a,b) -> all(value.(a) .≈ value.(b)))
#     @test 5Mean() == 5Mean()
# end
# #-----------------------------------------------------------------------# Hist 
# @testset "Hist" begin 
# @testset "FixedBins" begin
#     test_merge(Hist(-5:.1:5), y, y2)
#     for edges in (-5:5, collect(-5:5), [-5, -3.5, 0, 1, 4, 5.5])
#         for data in (y, -6:0.75:6)
#             h1 = fit(Histogram, data, edges, closed = :left).weights
#             test_exact(Hist(edges), data, o -> O.counts(o), y -> h1)

#             h2 = fit(Histogram, data, edges, closed = :right).weights
#             test_exact(Hist(edges; closed = :right), data, o -> O.counts(o), y -> h2)
#         end
#     end
#     test_exact(Hist(-5:.1:5), y, extrema, extrema, atol=.2)
#     test_exact(Hist(-5:.1:5), y, mean, mean, atol=.2)
#     test_exact(Hist(-5:.1:5), y, nobs, length)
#     test_exact(Hist(-5:.1:5), y, var, var, atol=.2)
#     test_merge(Hist(-5:.1:5), y, y2)
# end 
# @testset "AdaptiveBins" begin 
#     test_exact(Hist(1000), y, mean, mean)
#     test_exact(Hist(1000), y, nobs, length)
#     test_exact(Hist(1000), y, var, var)
#     test_exact(Hist(1000), y, median, median)
#     test_exact(Hist(1000), y, quantile, quantile)
#     test_exact(Hist(1000), y, std, std)
#     test_exact(Hist(1000), y, extrema, extrema, ==)
#     test_merge(Hist(2000), y, y2)
#     test_merge(Hist(1), y, y2)
#     test_merge(Hist(2000, Float32), Float32.(y), Float32.(y2))
#     test_merge(Hist(Float32, 2000), Float32.(y), Float32.(y2))
# end
# end
# #-----------------------------------------------------------------------# HyperLogLog 
# @testset "HyperLogLog" begin 
#     test_exact(HyperLogLog(12), y, value, y->length(unique(y)), atol=30)
#     test_merge(HyperLogLog(4), y, y2)
# end
@testset "LinReg" begin 
    test_exact(LinReg(), (x,y), value, x->x[1]\x[2])
    test_merge(LinReg(), (x,y), (x2,y2))
    # ridge 
    o = fit!(LinReg(), (x,y))
    @test coef(o) ≈ x \ y
    @test coef(o, .1) ≈ (x'x + 100 * I) \ x'y
    λ = rand(5)
    @test coef(o, λ) ≈ (x'x + 1000 * Diagonal(λ)) \ x'y
end
#-----------------------------------------------------------------------# Mean 
@testset "Mean" begin 
    test_exact(Mean(), y, mean, mean)
    test_merge(Mean(), y, y2)
end
#-----------------------------------------------------------------------# Moments
@testset "Moments" begin 
    test_exact(Moments(), y, value, x ->[mean(x), mean(x .^ 2), mean(x .^ 3), mean(x .^4) ])
    test_exact(Moments(), y, skewness, skewness, atol = .1)
    test_exact(Moments(), y, kurtosis, kurtosis, atol = .1)
    test_exact(Moments(), y, mean, mean)
    test_exact(Moments(), y, var, var)
    test_exact(Moments(), y, std, std)
    test_merge(Moments(), y, y2)
end
@testset "NBClassifier" begin 
    X, Y = randn(1000, 5), rand(Bool, 1000)
    X2, Y2 = randn(1000, 5), rand(Bool, 1000)
    Y[1] = Y2[1] = true
    o = fit!(NBClassifier(Bool, ()->5FitNormal()), (X, Y))
    o2 = fit!(NBClassifier(Bool, ()->5FitNormal()), (X2, Y2))
    merge!(o, o2)
    fit!(o2, (X, Y))
    @test sort(value(o)[1]) == sort(value(o2)[1])
    for i in 1:5, j in 1:2 
        @test value(o.d[true][i])[j] ≈ value(o2.d[true][i])[j]
    end
end
@testset "OrderStats" begin 
    test_merge(OrderStats(100), y, y2)
    test_exact(OrderStats(1000), y, value, sort, ==)
end
#-----------------------------------------------------------------------# Quantile
@testset "Quantile/PQuantile" begin 
    data = randn(10_000)
    data2 = randn(10_000)
    τ = .1:.1:.9
    for o in [
            Quantile(τ; alg = SGD()), 
            # Quantile(τ, MSPI()), 
            # Quantile(τ, OMAS()),
            Quantile(τ; alg = ADAGRAD())
            ]
        test_exact(copy(o), data, value, x -> quantile(x,τ), atol = .5)
        test_merge(copy(o), data, data2, atol = .5)
    end
    # for τi in τ
    #     test_exact(P2Quantile(τi), data, value, x->quantile(x, τi), atol = .3)
    # end
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
#-----------------------------------------------------------------------# StatLearn 
@testset "StatLearn" begin 

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
