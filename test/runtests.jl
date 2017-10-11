module OnlineStatsTest
using OnlineStats, Base.Test, LearnBase, StatsBase
using LossFunctions, PenaltyFunctions

# #-----------------------------------------------------------# coverage for show()
# info("Messy output for test coverage")
# @testset "show" begin
#     println(Series(Mean()))
#     println(Series(Mean(), Variance()))
#     println(Bootstrap(Series(Mean()), 100, [0, 2]))
#     println(Mean())
#     println(Variance())
#     println(OrderStats(5))
#     println(Moments())
#     println(Quantiles{:SGD}())
#     println(Quantiles())
#     println(QuantileMM())
#     # println(NormalMix(2))
#     println(MV(2, Mean()))
#     println(HyperLogLog(5))
#     println(KMeans(5,3))
#     println(LinReg(5))
#     println(StatLearn(5))
#     o = Mean()
#     Series(LearningRate(), o)
#     for stat in o
#         println(stat)
#     end
#     @testset "maprows" begin
#         s = Series(Mean(), Variance())
#         y = randn(100)
#         maprows(10, y) do yi
#             fit!(s, yi)
#             print("$(nobs(s)), ")
#         end
#         println()
#         @test nobs(s) == 100
#         @test value(s, 1) ≈ mean(y)
#         @test value(s, 2) ≈ var(y)
#     end
# end
#
#
#
# println()
# println()
# info("TESTS BEGIN HERE")
# #--------------------------------------------------------------------------------# TESTS
#
#
# moments(y) = [mean(y), mean(y.^2), mean(y.^3), mean(y.^4)]
# @testset "Summary" begin
#     y1 = randn(500)
#     y2 = randn(501)
#     y = vcat(y1, y2)
#     @testset "Quantiles" begin
#         s = @inferred Series(y1, Quantiles{:SGD}(), Quantiles(), QuantileMM())
#         @test typeof(s.weight) == LearningRate
#         s = @inferred Series(y1, Quantiles{:SGD}(), Quantiles(), QuantileMM())
#     end
#     @testset "Extra methods" begin
#         @test mean(Mean()) == 0.0
#         @test nobs(Variance()) == 0
#         @test extrema(Extrema()) == (Inf, -Inf)
#
#         y = randn(10000)
#         o = Moments()
#         s = Series(y, o)
#         @test mean(o) ≈ mean(y)
#         @test var(o) ≈ var(y)
#         @test std(o) ≈ std(y)
#         @test kurtosis(o) ≈ kurtosis(y) atol = .1
#         @test skewness(o) ≈ skewness(y) atol = .1
#
#         o1 = Quantiles([.4, .5])
#         o2 = Quantiles([.4, .5])
#         merge!(o1, o2, .5)
#
#         o = Diff(Int64)
#         @test typeof(o) == Diff{Int64}
#         fit!(o, 5, .1)
#
#         o = Sum(Int64)
#         @test sum(o) == 0
#         @test typeof(o) == Sum{Int64}
#         fit!(o, 5, .1)
#
#         y1 = randn(100)
#         y2 = randn(100)
#         s1 = Series(y1, Extrema())
#         s2 = Series(y2, Extrema())
#         merge!(s1, s2)
#         @test value(s1) == extrema(vcat(y1, y2))
#     end
# end
#
# @testset "Distributions" begin
#     # @testset "Distribution params" begin
#     #     function testdist(d::Symbol, wt = EqualWeight(), tol = 1e-4)
#     #         y = @eval rand($d(), 10_000)
#     #         o = @eval $(Symbol(:Fit, d))()
#     #         @test value(o) == @eval($d())
#     #         s = Series(y, wt, o)
#     #         fit!(s, y)
#     #         myfit = @eval fit($d, $y)
#     #         for i in 1:length(Distributions.params(o))
#     #             @test Distributions.params(o)[i] ≈ value(o) atol = tol
#     #         end
#     #     end
#     #     testdist(:Beta)
#     #     testdist(:Cauchy, LearningRate(), .1)
#     #     testdist(:Gamma, EqualWeight(), .1)
#     #     testdist(:LogNormal)
#     #     testdist(:Normal)
#     # end
#     @testset "sanity check" begin
#         value(Series(rand(100), FitBeta()))
#         value(Series(randn(100), FitCauchy()))
#         value(Series(rand(100) + 5, FitGamma()))
#         value(Series(rand(100) + 5, FitLogNormal()))
#         value(Series(randn(100), FitNormal()))
#     end
#     @testset "FitCategorical" begin
#         y = rand(1:5, 1000)
#         o = FitCategorical(Int)
#         s = Series(y, o)
#         for i in 1:5
#             @test i in keys(o)
#         end
#         vals = ["small", "big"]
#         s = Series(rand(vals, 100), FitCategorical(String))
#         value(s)
#     end
#     @testset "FitMvNormal" begin
#         y = randn(1000, 3)
#         o = FitMvNormal(3)
#         @test length(o) == 3
#         s = Series(y, o)
#         value(s)
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
# @testset "Bootstrap" begin
#     b = Bootstrap(Series(Mean()), 100, [0, 2])
#     fit!(b, randn(1000))
#     value(b)        # `fun` mapped to replicates
#     mean(value(b))  # mean
#     @test replicates(b) == b.replicates
#     confint(b)
#     confint(b, .95, :normal)
# end
# @testset "StatLearn" begin
#     n, p = 1000, 10
#     x = randn(n, p)
#     y = x * linspace(-1, 1, p) + .5 * randn(n)
#
#     for u in [SGD(), NSGD(), ADAGRAD(), ADADELTA(), RMSPROP(), ADAM(), ADAMAX()]
#         o = @inferred StatLearn(p, scaled(L2DistLoss(), .5), L2Penalty(), fill(.1, p), u)
#         s = @inferred Series(o)
#         fit!(s, x, y)
#         fit!(s, x, y, .1)
#         fit!(s, x, y, rand(length(y)))
#         @test nobs(s) == 3 * n
#         @test coef(o) == o.β
#         @test predict(o, x) == x * o.β
#         @test predict(o, x[1,:]) == x[1,:]'o.β
#         @test loss(o, x, y) == value(o.loss, y, predict(o, x), AvgMode.Mean())
#
#         o = StatLearn(p, LogitMarginLoss())
#         o.β[:] = ones(p)
#         @test classify(o, x) == sign.(vec(sum(x, 2)))
#
#         @testset "Type stability with arbitrary argument order" begin
#             l, r, v = L2DistLoss(), L2Penalty(), fill(.1, p)
#             @inferred StatLearn(p, l, r, v, u)
#             @inferred StatLearn(p, l, r, u, v)
#             @inferred StatLearn(p, l, v, r, u)
#             @inferred StatLearn(p, l, v, u, r)
#             @inferred StatLearn(p, l, u, v, r)
#             @inferred StatLearn(p, l, u, r, v)
#             @inferred StatLearn(p, l, r, v)
#             @inferred StatLearn(p, l, r, u)
#             @inferred StatLearn(p, l, v, r)
#             @inferred StatLearn(p, l, v, u)
#             @inferred StatLearn(p, l, u, v)
#             @inferred StatLearn(p, l, u, r)
#             @inferred StatLearn(p, l, r)
#             @inferred StatLearn(p, l, r)
#             @inferred StatLearn(p, l, v)
#             @inferred StatLearn(p, l, v)
#             @inferred StatLearn(p, l, u)
#             @inferred StatLearn(p, l, u)
#             @inferred StatLearn(p, l)
#             @inferred StatLearn(p, r)
#             @inferred StatLearn(p, v)
#             @inferred StatLearn(p, u)
#             @inferred StatLearn(p)
#         end
#     end
# end
# @testset "LinReg" begin
#     n, p = 1000, 10
#     x = randn(n, p)
#     y = x * linspace(-1, 1, p) + randn(n)
#
#     o = LinReg(p)
#     s = Series(o)
#     fit!(s, x, y)
#     @test nobs(s) == n
#     @test nobs(o) == n
#     @test coef(o) == value(o)
#     @test coef(o) ≈ x\y
#
#     # merge
#     n2 = 500
#     x2 = randn(n2, p)
#     y2 = x2 * linspace(-1, 1, p) + randn(n2)
#     o1 = LinReg(p)
#     o2 = LinReg(p)
#     s1 = Series(o1)
#     s2 = Series(o2)
#     fit!(s1, x, y)
#     fit!(s2, x2, y2)
#     merge!(s1, s2)
#     @test coef(o1) ≈ vcat(x, x2) \ vcat(y, y2)
#
#     mse(o)
#     # coeftable(o)
#     # confint(o)
#     vcov(o)
#     stderr(o)
#
#     o = LinReg(p, .1)
#     s = Series(o)
#     fit!(s, x, y)
#     value(o)
#     @test predict(o, x) == x * o.β
# end


end
