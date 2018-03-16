#-----------------------------------------------------------------------# AutoCov
@testset "AutoCov" begin 
    test_exact(AutoCov(10), y, autocov, x -> autocov(x, 0:10))
    test_exact(AutoCov(10), y, autocor, x -> autocor(x, 0:10))
    test_exact(AutoCov(10), y, nobs, length)
end
# #-----------------------------------------------------------------------# Bootstrap 
# @testset "Bootstrap" begin 
#     o = Bootstrap(Mean(), 100, [1])
#     Series(y, o)
#     @test all(value.(o.replicates) .== value(o))
#     @test length(confint(o)) == 2
# end
#-----------------------------------------------------------------------# Count 
@testset "Count" begin 
    test_exact(Count(), randn(100), value, length)
    test_merge(Count(), rand(100), rand(100), ==)
end
#-----------------------------------------------------------------------# CountMap
@testset "CountMap" begin
    test_exact(CountMap(Int), rand(1:10, 100), nobs, length, ==)
    test_exact(CountMap(Int), rand(1:10, 100), o->sort(value(o)), x->sort(countmap(x)), ==)
    test_exact(CountMap(Int), [1,2,3,4], o->OnlineStats.pdf(o,1), x->.25, ==)
    test_merge(CountMap(SortedDict{Bool, Int}()), [rand(Bool, 100)], rand(Bool, 100), ==)
    test_merge(CountMap(SortedDict{Bool, Int}()), trues(100), falses(100), ==)
    test_merge(CountMap(SortedDict{Int, Int}()), rand(1:4, 100), rand(5:123, 50), ==)
    test_merge(CountMap(SortedDict{Int, Int}()), rand(1:4, 100), rand(5:123, 50), ==)
    o = fit!(CountMap(Int), [1,2,3,4])
    @test all([1,2,3,4] .∈ keys(o.value))
    @test probs(o) == fill(.25, 4)
    @test probs(o, 7:9) == zeros(3)
end
# #-----------------------------------------------------------------------# CovMatrix
# @testset "CovMatrix" begin 
#     test_exact(CovMatrix(5), x, var, x -> vec(var(x, 1)))
#     test_exact(CovMatrix(5), x, std, x -> vec(std(x, 1)))
#     test_exact(CovMatrix(5), x, mean, x -> vec(mean(x, 1)))
#     test_exact(CovMatrix(5), x, cor, cor)
#     test_exact(CovMatrix(5), x, cov, cov)
#     test_exact(CovMatrix(5), x, o->cov(o;corrected=false), x->cov(x,1,false))
#     test_merge(CovMatrix(5), x, x2)
# end
# #-----------------------------------------------------------------------# CStat 
# @testset "CStat" begin 
#     data = y + y2 * im 
#     data2 = y2 + y * im
#     test_exact(CStat(Mean()), data, o->value(o)[1], x -> mean(y))
#     test_merge(CStat(Mean()), y, y2)
#     test_merge(CStat(Mean()), data, data2)
# end
# #-----------------------------------------------------------------------# Diff 
# @testset "Diff" begin 
#     test_exact(Diff(), y, value, y -> y[end] - y[end-1])
#     o = Diff(Int)
#     Series(1:10, o)
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
# #-----------------------------------------------------------------------# Distributions
# @testset "Fit[Distribution]" begin
#     @testset "sanity check" begin
#         value(Series(rand(100), FitBeta()))
#         value(Series(randn(100), FitCauchy()))
#         value(Series(rand(100) + 5, FitGamma()))
#         value(Series(rand(100) + 5, FitLogNormal()))
#         value(Series(randn(100), FitNormal()))
#     end
#     @testset "FitBeta" begin
#         o = FitBeta()
#         @test value(o) == (1.0, 1.0)
#         Series(rand(200), o)
#         @test value(o)[1] ≈ 1.0 atol=.4
#         @test value(o)[2] ≈ 1.0 atol=.4
#         test_exact(FitBeta(), rand(500), value, x->[1,1], (a,b) -> ≈(a,b;atol=.3))
#         test_merge(FitBeta(), rand(50), rand(50))
#     end
#     @testset "FitCauchy" begin
#         o = FitCauchy()
#         @test value(o) == (0.0, 1.0)
#         Series(randn(100), o)
#         @test value(o) != (0.0, 1.0)
#         merge!(o, FitCauchy(), .5)
#     end
#     @testset "FitGamma" begin
#         o = FitGamma()
#         @test value(o) == (1.0, 1.0)
#         Series(rand(100) + 5, o)
#         @test value(o)[1] > 0
#         @test value(o)[2] > 0
#         test_merge(FitGamma(), rand(100) + 5, rand(100) + 5)
#     end
#     @testset "FitLogNormal" begin
#         o = FitLogNormal()
#         @test value(o) == (0.0, 1.0)
#         Series(exp.(randn(100)), o)
#         @test value(o)[1] != 0
#         @test value(o)[2] > 0
#         test_merge(FitLogNormal(), exp.(randn(100)), exp.(randn(100)))
#     end
#     @testset "FitNormal" begin
#         o = FitNormal()
#         @test value(o) == (0.0, 1.0)
#         Series(y, o)
#         @test value(o)[1] ≈ mean(y)
#         @test value(o)[2] ≈ std(y)
#         test_merge(FitNormal(), randn(100), randn(100))
#     end
#     @testset "FitMultinomial" begin
#         o = FitMultinomial(5)
#         @test value(o)[2] == ones(5) / 5
#         s = Series([1,2,3,4,5], o)
#         fit!(s, [1, 2, 3, 4, 5])
#         @test value(o)[2] == [1, 2, 3, 4, 5] ./ 15
#         test_merge(FitMultinomial(3), [1,2,3], [2,3,4])
#     end
#     @testset "FitMvNormal" begin
#         data = randn(1000, 3)
#         o = FitMvNormal(3)
#         @test value(o) == (zeros(3), eye(3))
#         @test length(o) == 3
#         s = Series(data, o)
#         @test value(o)[1] ≈ vec(mean(data, 1))
#         @test value(o)[2] ≈ cov(data)
#         test_merge(FitMvNormal(3), randn(10,3), randn(10,3))
#     end
# end
# #-----------------------------------------------------------------------# Group 
# @testset "Group" begin 
#     o = Group(Mean(), Mean(), Mean(), Variance(), Variance())
#     @test o[1] == first(o) == Mean()
#     @test o[5] == last(o) == Variance()
#     test_exact(o, x, value, x -> vcat(mean(x,1)[1:3], var(x,1)[4:5]))
#     test_merge([Mean() Variance() Sum() Moments() Mean()], x, x2)
#     s = Series(x, 5Mean())
#     xmeans = mean(x, 1)
#     for (i, stat) in enumerate(s.stats[1])
#         @test value(stat) ≈ xmeans[i]
#     end
#     test_exact(5Mean(), x, value, x->vec(mean(x,1)))
#     test_merge(5Mean(), x, x2)
#     test_exact(5Variance(), x, value, x->vec(var(x,1)))
#     test_merge(5Variance(), x, x2)
#     @test 5Mean() == 5Mean()
# end
# #-----------------------------------------------------------------------# Hist 
# @testset "Hist" begin
#     dpdf = OnlineStats.pdf
#     #### FixedBins
#     for edges in (-5:5, collect(-5:5), [-5, -3.5, 0, 1, 4, 5.5])
#         for data in (y, -6:0.75:6)
#             test_exact(Hist(edges), data, o -> value(o)[2],
#                        y -> fit(Histogram, y, edges, closed = :left).weights)
#             test_exact(Hist(edges; closed = :right), data, o -> value(o)[2],
#                        y -> fit(Histogram, y, edges, closed = :right).weights)
#         end
#     end
#     test_exact(Hist(-5:.1:5), y, extrema, extrema, (a,b)->≈(a,b;atol=.2))
#     test_exact(Hist(-5:.1:5), y, mean, mean, (a,b)->≈(a,b;atol=.2))
#     test_exact(Hist(-5:.1:5), y, nobs, length)
#     test_exact(Hist(-5:.1:5), y, var, var, (a,b)->≈(a,b;atol=.2))
#     test_merge(Hist(-5:.1:5), y, y2)
#     # merge with different edges
#     o, o2 = Hist(-6:6), Hist(-6:.1:6)
#     Series(y, o, o2)
#     c = copy(value(o)[2])
#     merge!(o, o2, .5)
#     @test all(value(o)[2] .== 2c)
#     #### AdaptiveBins
#     test_exact(Hist(AdaptiveBins(Pair{Float64, Int}[], 100)), y, mean, mean)
#     test_exact(Hist(100), y, mean, mean)
#     test_exact(Hist(100), y, nobs, length)
#     test_exact(Hist(100), y, var, var)
#     test_exact(Hist(100), y, median, median)
#     test_exact(Hist(100), y, quantile, quantile)
#     test_exact(Hist(100), y, std, std)
#     test_exact(Hist(100), y, extrema, extrema, ==)
#     test_merge(Hist(200), y, y2)
#     test_merge(Hist(1), y, y2)
#     test_merge(Hist(200, Float32), Float32.(y), Float32.(y2))
#     test_merge(Hist(Float32, 200), Float32.(y), Float32.(y2))
#     s = Series(y, Hist(5))
#     # pdf
#     data = randn(1_000)
#     for o in [Hist(-5:5), Hist(-3:.5:3), Hist(5), Hist(20), Hist(100)]
#         Series(data, o)
#         @test dpdf(o, 0) ≥ 0 
#         @test dpdf(o, -10) == 0
#         @test dpdf(o, 10) == 0
#         @test quadgk(x -> dpdf(o, x), collect(-10:10)...)[1] ≈ 1 atol=.1
#     end
#     o = Hist(0:.05:1)
#     Series(data, o)
#     @test quadgk(x -> dpdf(o, x), collect(-10:10)...)[1] ≈ 1 atol=.1
# end
# #-----------------------------------------------------------------------# HyperLogLog 
# @testset "HyperLogLog" begin 
#     test_exact(HyperLogLog(12), y, value, y->length(unique(y)), (a,b) -> ≈(a,b;atol=3))
#     test_merge(HyperLogLog(4), y, y2)
# end
# #-----------------------------------------------------------------------# IndexedPartition 
# @testset "IndexedPartition" begin 
#     test_exact(IndexedPartition(Float64, Mean()), [y y2], o -> value(merge(o)), x->mean(y2))
#     test_exact(IndexedPartition(Float64, Mean(), 2), [y y2], o -> value(merge(o)), x->mean(y2))
#     o = IndexedPartition(Int, Mean())
#     @test value(o) == []
#     fit!(o, (1, 1.0))
#     @test value(o) == [1.0]
#     # merge 
#     o, o2 = IndexedPartition(Float64, Mean()), IndexedPartition(Float64, Mean())
#     s, s2 = Series([y y2], o), Series([y y2], o2)
#     merge!(s, s2)
#     @test value(merge(o)) ≈ value(merge(o2))
#     # merge 2
#     o, o2 = IndexedPartition(Float64, Mean()), IndexedPartition(Float64, Mean())
#     s, s2 = Series([y y2], o), Series([y y2], o2)
#     merge!(s, s2)
#     # with Date 
#     data = (Date(2010):Date(2011))[1:100]
#     test_exact(IndexedPartition(Date, Mean()), [data y], o -> value(merge(o)), x->mean(y))
# end
# #-----------------------------------------------------------------------# KMeans
# @testset "KMeans" begin 
#     s = Series(x, KMeans(5, 2))
#     @test size(value(s)[1]) == (5, 2)
#     # means: [0, 0] and [10, 10]
#     data = 10rand(Bool, 2000) .+ randn(2000, 2)
#     o = KMeans(2, 2)
#     Series(LearningRate(.9), data, o)
#     m1, m2 = value(o)[:, 1], value(o)[:, 2]
#     @test ≈(m1, [0, 0]; atol=.5) || ≈(m2, [0, 0]; atol=.5)
#     @test ≈(m1, [10, 10]; atol=.5) || ≈(m2, [10, 10]; atol=.5)
# end
# #-----------------------------------------------------------------------# LinReg 
# @testset "LinReg" begin 
#     test_exact(LinReg(5), (x,y), coef, xy -> xy[1]\xy[2])
#     test_exact(LinReg(5), (x,y), nobs, xy -> length(xy[2]))
#     βridge = inv(x'x/100 + .1I) * x'y/100
#     test_exact(LinReg(5, .1), (x,y), coef, x -> βridge)
#     test_merge(LinReg(5), (x,y), (x2,y2))
#     test_merge(LinReg(5, .1), (x,y), (x2,y2))
#     # predict
#     o = LinReg(5)
#     Series((x,y), o)
#     @test predict(o, x, Rows()) == x * o.β
#     @test predict(o, x', Cols()) ≈ x * o.β
#     @test predict(o, x[1,:]) == x[1,:]' * o.β
# end
# #-----------------------------------------------------------------------# LinRegBuilder 
# @testset "LinRegBuilder" begin 
#     test_exact(LinRegBuilder(6), [x y], o -> coef(o;bias=false,y=6), f -> x\y)
#     test_merge(LinRegBuilder(5), x, x2)
# end
# #-----------------------------------------------------------------------# Mean 
# @testset "Mean" begin 
#     test_exact(Mean(), y, mean, mean)
#     test_merge(Mean(), y, y2)
# end
# #-----------------------------------------------------------------------# Moments
# @testset "Moments" begin 
#     test_exact(Moments(), y, value, x ->[mean(x), mean(x .^ 2), mean(x .^ 3), mean(x .^4) ])
#     test_exact(Moments(), y, skewness, skewness, (a,b) -> ≈(a,b,atol=.1))
#     test_exact(Moments(), y, kurtosis, kurtosis, (a,b) -> ≈(a,b,atol=.1))
#     test_exact(Moments(), y, mean, mean)
#     test_exact(Moments(), y, var, var)
#     test_exact(Moments(), y, std, std)
#     test_merge(Moments(), y, y2)
# end
# @testset "Mosaic" begin 
#     data = rand(Bool, 100, 2)
#     s = series(data, Mosaic(Bool, Bool))
#     @test keys(s.stats[1]) == [false, true]
#     @test OnlineStats.subkeys(s.stats[1]) == [false, true]
# end
# #-----------------------------------------------------------------------# MV 
# @testset "MV" begin 
#     o = MV(5, Mean())
#     @test length(o) == 5
#     test_exact(MV(5, Mean()), x, value, x->vec(mean(x,1)))
#     test_merge(MV(5, Mean()), x, x2)
#     test_exact(MV(5, Variance()), x, value, x->vec(var(x,1)))
#     test_merge(MV(5, Variance()), x, x2)
#     @test MV(5, Mean()) == MV(5, Mean())
#     @test length(MV(10, Quantile())) == 10
# end
# #-----------------------------------------------------------------------# NBClassifier
# @testset "NBClassifier" begin 
#     n, p = 20000, 5
#     X = randn(n, p)
#     Y = X * linspace(-1, 1, p) .> 0
#     o = NBClassifier(Group(p, Hist(100)), Bool)
#     Series((X, Y), o)
#     @test classify(o, [0,0,0,0,1])
#     X2 = [zeros(p) zeros(p) zeros(p) rand(p) 1 .+ rand(p)]
#     @test all(classify(o, X2))
#     @test all(classify(o, X2', Cols()))
#     # Sanity check for predict 
#     predict(o, [0,0,0,0,1])[2]
#     predict(o, X2)
#     predict(o, X2', Cols())
# end
# #-----------------------------------------------------------------------# OrderStats 
# @testset "OrderStats" begin 
#     test_exact(OrderStats(100), y, value, sort)
#     test_exact(OrderStats(100), y, quantile, quantile)
#     test_merge(OrderStats(10), y, y2, (a,b) -> ≈(a,b;atol=.1))  # Why does this need atol?
#     test_exact(OrderStats(100, Int), rand(1:10, 100), value, sort)
#     test_exact(OrderStats(100), y, nobs, length)
# end
# #-----------------------------------------------------------------------# Partition 
# @testset "Partition" begin 
#     @testset "Part" begin 
#         o = OnlineStats.Part(Mean(), 1, 1)
#         @test first(o) == 1 
#         @test last(o) == 1
#         @test value(o) == 1
#         @test o < OnlineStats.Part(Mean(), 2, 1)
#         @test_throws Exception fit!(o, 5, 1)
#         fit!(o, 1, 3)
#         @test value(o) ≈ 2
#     end
#     # merge(o)
#     test_exact(Partition(Mean(),7), y, o -> value(merge(o)), mean)
#     test_exact(Partition(Variance(),8), y, o -> value(merge(o)), var)
#     # number of parts stays between b and 2b
#     o = Partition(Mean(), 15)
#     @test value(o) == []
#     for i in 1:10
#         fit!(o, y)
#         @test 15 ≤ length(o.parts) ≤ 30
#     end
#     # merge(o, o2)
#     data, data2 = randn(1000), randn(1234)
#     o = Partition(Mean())
#     o2 = Partition(Mean())
#     s = merge!(Series(data, o), Series(data2, o2))
#     @test value(merge(o)) ≈ mean(vcat(data, data2))
# end
# #-----------------------------------------------------------------------# ProbMap 
# @testset "ProbMap" begin 
#     test_merge(ProbMap(Int), rand(1:5, 100), rand(1:5, 100), (a,b)->collect(keys(a))==collect(keys(b)))
#     test_merge(ProbMap(Int), rand(1:5, 100), rand(1:5, 100), (a,b)->collect(values(a))≈collect(values(b)))
#     test_exact(ProbMap(Int), [1,2,1,2,1,2], o->collect(values(sort(value(o)))), x->[.5, .5])
#     test_exact(ProbMap(Int), [1,1,1,2], o->collect(values(sort(value(o)))), x->[.75, .25])
#     s = series([1,2,3,4], ProbMap(Int))
#     @test 1 in keys(s.stats[1])
#     @test haskey(s.stats[1], 2)
#     @test .25 in values(s.stats[1])
#     @test probs(s.stats[1]) == fill(.25, 4)
#     @test probs(s.stats[1], 5:7) == zeros(3)
# end
# #-----------------------------------------------------------------------# Quantile
# @testset "Quantile/PQuantile" begin 
#     data = randn(10_000)
#     data2 = randn(10_000)
#     τ = .1:.1:.9
#     for o in [
#             Quantile(τ, SGD()), 
#             Quantile(τ, MSPI()), 
#             Quantile(τ, OMAS()),
#             Quantile(τ, ADAGRAD())
#             ]
#         test_exact(o, data, value, x -> quantile(x,τ), (a,b) -> ≈(a,b,atol=.5))
#         test_merge(o, data, data2, (a,b) -> ≈(a,b,atol=.5))
#     end
#     for τi in τ
#         test_exact(PQuantile(τi), data, value, x->quantile(x, τi), (a,b) -> ≈(a,b;atol=.3))
#     end
#     @test_throws Exception Quantile(τ, ADAM())
# end
# #-----------------------------------------------------------------------# ReservoirSample
# @testset "ReservoirSample" begin 
#     test_exact(ReservoirSample(100), y, value, identity, ==)
#     test_exact(ReservoirSample(7), y, o -> all(in.(value(o), [y])), x->true)
#     # merge
#     s = Series(y, ReservoirSample(9))
#     s2 = Series(y2, ReservoirSample(9))
#     merge!(s, s2)
#     fit!(s2, y)
#     for yi in value(s2.stats[1])
#         @test (yi ∈ y) || (yi ∈ y2)
#     end
# end
# #-----------------------------------------------------------------------# StatLearn
# @testset "StatLearn" begin
#     n, p = 1000, 10
#     X = randn(n, p)
#     Y = X * linspace(-1, 1, p) + .5 * randn(n)

#     for u in [SGD(), NSGD(), ADAGRAD(), ADADELTA(), RMSPROP(), ADAM(), ADAMAX(), NADAM(), 
#               MSPI(), OMAP(), OMAS()]
#         o = @inferred StatLearn(p, .5 * L2DistLoss(), L2Penalty(), fill(.1, p), u)
#         s = @inferred Series(o)
#         @test value(o, X, Y) == value(.5 * L2DistLoss(), Y, zeros(Y), AvgMode.Mean())
#         fit!(s, (X, Y))
#         @test nobs(s) == n
#         @test coef(o) == o.β
#         @test predict(o, X) == X * o.β
#         @test predict(o, X', Cols()) ≈ X * o.β
#         @test predict(o, X[1,:]) == X[1,:]'o.β
#         @test loss(o, X, Y) == value(o.loss, Y, predict(o, X), AvgMode.Mean())

#         # sanity check for merge!
#         merge!(StatLearn(4, u), StatLearn(4, u), .5)

#         o = StatLearn(p, LogitMarginLoss())
#         o.β[:] = ones(p)
#         @test classify(o, X) == sign.(vec(sum(X, 2)))

#         os = OnlineStats.statlearnpath(o, 0:.01:.1)
#         @test length(os) == length(0:.01:.1)

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
#         fit!(o, (randn(p), randn()))
#     end
#     @testset "MM-based" begin
#         X, Y = randn(100, 5), randn(100)
#         @test_throws ErrorException Series((X,Y), StatLearn(5, PoissonLoss(), OMAS()))
#     end
# end
# #-----------------------------------------------------------------------# Sum 
# @testset "Sum" begin 
#     test_exact(Sum(), y, sum, sum)
#     test_exact(Sum(Int), 1:100, sum, sum)
#     test_merge(Sum(), y, y2)
# end
# #-----------------------------------------------------------------------# Unique 
# @testset "Unique" begin 
#     test_exact(Unique(Float64), y, unique, x->sort(unique(x)))
#     test_exact(Unique(Float64), y, length, length, ==)
#     test_merge(Unique(Float64), y, y2, ==)
# end
# #-----------------------------------------------------------------------# Variance 
# @testset "Variance" begin 
#     test_exact(Variance(), y, mean, mean)
#     test_exact(Variance(), y, std, std)
#     test_exact(Variance(), y, var, var)
#     test_merge(Variance(), y, y2)
# end
