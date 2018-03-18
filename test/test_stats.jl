


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


