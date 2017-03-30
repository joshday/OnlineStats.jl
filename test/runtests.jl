module OnlineStatsTest
using OnlineStats, Base.Test, Distributions

#-----------------------------------------------------------# coverage for show() methods
info("Messy output for test coverage")
@testset "show" begin
    println(Series(Mean()))
    println(OnlineStats.name(Moments(), false))
    println(Mean())
    println(OrderStats(5))
    println(Moments())
    println(QuantileMM())
    println(NormalMix(2))
    println(MV(2, Mean()))
    println(HyperLogLog(5))
    println(KMeans(5,3))
    for w in [EqualWeight(), ExponentialWeight(), BoundedEqualWeight(), LearningRate(),
              LearningRate2()]
        println(w)
    end
    # @testset "maprows" begin
    #     s = Series(tuple(Mean(), Variance()))
    #     println()
    #     maprows(10, randn(100)) do yi
    #         fit!(s, yi)
    #         print("$(nobs(s)), ")
    #     end
    #     println()
    #     @test nobs(s) == 100
    # end
end



println()
println()
info("TESTS BEGIN HERE")
#--------------------------------------------------------------------------------# TESTS
#--------------------------------------------------------------------------------# Weights
@testset "Weights" begin
    w1 = @inferred EqualWeight()
    w2 = @inferred ExponentialWeight()
    w3 = @inferred BoundedEqualWeight()
    w4 = @inferred LearningRate()
    w5 = @inferred LearningRate2()

    for w in [w1, w3, w4]
        @test OnlineStats.weight(w, 1, 1, 1) == 1
    end
    for i in 1:10
        @test OnlineStats.weight(w1, i, 1, i) == 1 / i
        @test OnlineStats.weight(w2, i, 1, i) == w2.λ
        @test OnlineStats.weight(w3, i, 1, i) == 1 / i
        @test OnlineStats.weight(w4, i, 1, i) ≈ i ^ -w4.r
        @test OnlineStats.weight(w5, i, 1, i) ≈ 1 / (1 + w5.c * (i-1))
    end
    @test OnlineStats.weight(w3, 1_000_000, 1, 1_000_000) == w3.λ

    @inferred ExponentialWeight(100)
    @inferred BoundedEqualWeight(100)
end
#-----------------------------------------------------------------------------# Series
@testset "Series" begin
    @test_throws ArgumentError Series(Mean(), CovMatrix(3))
end
@testset "Series{0}" begin
    for o in (Mean(), Variance(), Extrema(), OrderStats(10), Moments(), QuantileSGD(),
              QuantileMM(), Diff(), Sum())
        y = randn(100)
        @testset "typeof(stats) <: OnlineStat" begin
            s = @inferred Series(o)
            @test isa(s, Series{0, <: OnlineStat})
            fit!(s, y)
            @test nobs(s) == 100
            @test value(s) == value(o)
        end
        @testset "typeof(stats) <: Tuple" begin
            s = @inferred Series(tuple(o))
            @test isa(s, Series{0, <: Tuple})
            fit!(s, y)
            @test nobs(s) == 100
            @test value(s) == tuple(value(o))
            @test value(s, 1) == value(o)
        end
    end
end
@testset "Series{1}" begin
    for o in [MV(4, Mean()), CovMatrix(4)]
        y = randn(100, 4)
        @testset "typeof(stats) <: OnlineStat" begin
            s = @inferred Series(o)
            fit!(s, y)
            @test isa(s, Series{1, <: OnlineStat})
            @test nobs(s) == 100
            @test value(s) == value(o)
        end
        @testset "typeof(stats) <: Tuple" begin
            s = @inferred(Series(tuple(o)))
            fit!(s, y)
            @test isa(s, Series{1, <: Tuple})
            @test nobs(s) == 100
            @test value(s) == tuple(value(o))
        end
    end
end

# @testset "Series merge" begin
#     y1 = randn(100)
#     y2 = randn(100)
#     y = vcat(y1, y2)
#     o1 = @inferred Series(Mean(), Variance())
#     o2 = @inferred Series(Mean(), Variance())
#     fit!(o1, y1)
#     fit!(o2, y2)
#
#     o3 = merge(o1, o2)
#     @test value(o3, 1) ≈ mean(y)
#     @test value(o3, 2) ≈ var(y)
#
#     merge(o1, o2, :mean)
#     merge(o1, o2, :singleton)
#     @test_throws ArgumentError merge(o1, o2, :not_a_real_method)
#     @inferred merge(Mean(), Mean(), .1)
# end
#
@testset "Summary" begin
    y1 = randn(500)
    y2 = randn(501)
    y = vcat(y1, y2)
    @testset "Mean" begin
    end
end
#     @testset "Mean" begin
#         o1 = @inferred Series(y1, Mean())
#         @test value(o1, 1) ≈ mean(y1)
#         @test nobs(o1) == 500
#
#         o2 = @inferred Series(y2, Mean())
#         @test value(o2, 1) ≈ mean(y2)
#
#         o3 = merge(o1, o2)
#         @test value(o3, 1) ≈ mean(y)
#         @test mean(stats(o3, 1)) ≈ mean(y)
#
#         s = @inferred Series(Mean())
#         fit!(s, y1, 10)
#         @test mean(stats(s, 1)) ≈ mean(y1)
#     end
#     @testset "Variance" begin
#         o1 = @inferred Series(y1, Variance())
#         @test value(o1, 1) ≈ var(y1)
#     end
#     @testset "Extrema" begin
#         o = @inferred Series(y1, Extrema())
#         @test value(o, 1) == extrema(y1)
#     end
#     @testset "QuantileMM/QuantileSGD" begin
#         o = @inferred Series(y1, QuantileMM(.1, .2, .3), QuantileSGD(.4, .5))
#         o = Series(y1, QuantileMM(), QuantileSGD(); weight = LearningRate())
#         fit!(o, y2, 5)
#
#         o = QuantileMM()
#         OnlineStats.fitbatch!(o, randn(10), .1)
#         o = QuantileSGD()
#         OnlineStats.fitbatch!(o, randn(10), .1)
#     end
#     @testset "Moments" begin
#         x = randn(10_000)
#         s = @inferred Series(x, Moments())
#         o = stats(s, 1)
#         @test mean(o)       ≈ mean(x)       atol = 1e-4
#         @test var(o)        ≈ var(x)        atol = 1e-4
#         @test std(o)        ≈ std(x)        atol = 1e-4
#         @test skewness(o)   ≈ skewness(x)   atol = 1e-3
#         @test kurtosis(o)   ≈ kurtosis(x)   atol = 1e-3
#
#         x2 = randn(1000)
#         s2 = Series(x2, Moments())
#         merge!(s, s2)
#         @test nobs(s) == 11_000
#
#         @test value(s, 1) ≈ value(Series(vcat(x, x2), Moments()), 1)
#     end
#     @testset "Diff" begin
#         @inferred Diff()
#         Diff(Float64)
#         Diff(Float32)
#         Diff(Int64)
#         Diff(Int32)
#         y = randn(100)
#         s = Series(y, Diff())
#         o = stats(s, 1)
#         @test typeof(o) == Diff{Float64}
#         @test last(o) == y[end]
#         @test diff(o) == y[end] - y[end-1]
#
#         y = rand(Int, 100)
#         s = @inferred Series(y, Diff(Int))
#         o = stats(s, 1)
#         @test typeof(o) == Diff{Int}
#         @test last(o) == y[end]
#         @test diff(o) == y[end] - y[end-1]
#     end
#     @testset "Sum" begin
#         Sum()
#         Sum(Float64)
#         Sum(Float32)
#         Sum(Int64)
#         Sum(Int32)
#
#         y = randn(100)
#         s = Series(y, Sum())
#         o = stats(s, 1)
#         @test typeof(o) == Sum{Float64}
#         @test sum(o) ≈ sum(y)
#         @test value(o) == sum(o)
#
#         y = rand(Int, 100)
#         s = Series(y, Sum(Int))
#         o = stats(s, 1)
#         @test typeof(o) == Sum{Int}
#         @test sum(o) ≈ sum(y)
#     end
# end # summary
#
#
#
# @testset "Distributions" begin
#     @testset "Distribution params" begin
#         function testdist(d::Symbol, wt = EqualWeight(), tol = 1e-4)
#             y = @eval rand($d(), 10_000)
#             o = @eval $(Symbol(:Fit, d))()
#             @test value(o) == @eval($d())
#             s = Series(y, o; weight = wt)
#             fit!(s, y)
#             myfit = @eval fit($d, $y)
#             for i in 1:length(params(o))
#                 @test params(o)[i] ≈ params(myfit)[i] atol = tol
#             end
#         end
#         testdist(:Beta)
#         testdist(:Cauchy, LearningRate(), .1)
#         testdist(:Gamma, EqualWeight(), .1)
#         testdist(:LogNormal)
#         testdist(:Normal)
#     end
#     @testset "FitCategorical" begin
#         y = rand(1:5, 1000)
#         o = FitCategorical(Int)
#         s = Series(y, o)
#         myfit = fit(Categorical, y)
#         pr = probs(value(o))
#         for i in eachindex(pr)
#             @test pr[i] in probs(myfit)
#         end
#         for i in 1:5
#             @test i in keys(o)
#         end
#     end
#     @testset "FitMultinomial" begin
#         y = rand(Multinomial(10, ones(5) / 5), 1000)
#         myfit = fit(Multinomial, y)
#         o = FitMultinomial(5)
#         @test params(value(o)) == (1, ones(5) / 5)
#         s = MvSeries(o)
#         fit!(s, y')
#         @test probs(o) ≈ probs(myfit)
#     end
#     @testset "FitMvNormal" begin
#         y = rand(MvNormal(zeros(3), eye(3)), 1000)
#         myfit = fit(MvNormal, y)
#         o = FitMvNormal(3)
#         @test length(o) == 3
#         @test params(value(o))[1] == zeros(3)
#         s = MvSeries(y', o)
#         @test mean(o) ≈ mean(myfit)
#     end
#     @testset "NormalMix" begin
#         d = MixtureModel([Normal(), Normal(1,2), Normal(2, 3)])
#         y = rand(d, 1000)
#         o = NormalMix(3, y)
#         s = Series(y, o)
#         fit!(s, y, 10)
#         components(o)
#         @test isa(component(o, 1), Normal)
#         component(o, 2)
#         component(o, 3)
#         @test ncomponents(o) == 3
#     end
# end
# @testset "HyperLogLog" begin
#     o = HyperLogLog(10)
#     for d in 4:16
#         o = HyperLogLog(d)
#         @test value(o) == 0.0
#         s = Series(o)
#         fit!(s, rand(1:10, 1000))
#         @test 8 < value(o) < 12
#     end
#     @test_throws Exception HyperLogLog(1)
# end
# @testset "CovMatrix" begin
#     x = randn(100, 5)
#     o = CovMatrix(5)
#     s = MvSeries(x, o)
#     @test nobs(s) == 100
#     fit!(s, x, 10)
#     OnlineStats.fitbatch!(o, x, .1)
#
#     o = CovMatrix(5)
#     s = MvSeries(o)
#     fit!(s, x, 10)
#     @test mean(o) ≈ vec(mean(x, 1))
#     @test var(o) ≈ vec(var(x, 1))
#     @test cov(o) ≈ cov(x) atol=.001
#     @test cor(o) ≈ cor(x) atol=.001
#     @test std(o) ≈ vec(std(x, 1))
#
#     x2 = randn(101, 5)
#     o2 = CovMatrix(5)
#     s2 = MvSeries(o2)
#     fit!(s2, x2, 10)
#     merge!(s, s2)
#     @test nobs(s) == 201
#     @test cov(o) ≈ cov(vcat(x, x2))
# end
# @testset "KMeans" begin
#     x = randn(100, 3)
#     o = KMeans(3, 5)
#     s = MvSeries(x, o)
#     fit!(s, x, 5)
# end
# @testset "Bootstrap" begin
#     y = randn(1000)
#     b = Bootstrap(100, Mean(), mean, Poisson())
#     fit!(b, y)
#     @test replicates(b) == b.replicates
#     @test b.cache_is_dirty
#     cached_state(b)
#     @test !b.cache_is_dirty
#
#     mean(b)
#     std(b)
#     var(b)
#     confint(b)
#     confint(b, .9, :normal)
#     @test_throws ArgumentError confint(b, .9, :badarg)
#     b.cached_state[1] = NaN
#     @test all(isnan, confint(b))
#
#     y = randn(1000)
#     b = Bootstrap(100, Mean(), mean, Bernoulli())
#     fit!(b, y)
#
#     b = MvBootstrap(MV(5, Mean()))
#     fit!(b, randn(1000, 5))
# end


end
