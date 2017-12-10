module OnlineStatsTest

using OnlineStats, Base.Test
using StatsBase

#-----------------------------------------------------------------------# helpers
# test: merge is same as fit!
function test_merge(o1, o2, y1, y2)
    s1 = @inferred Series(y1, o1)
    s2 = Series(y2, o2)
    merge!(s1, s2)
    fit!(s2, y1)
    @test all(value(o1) .≈ value(o1))
end

# # test: value(o) == f(y)
# function test_exact(o, y, f; kw...)
#     s = @inferred Series(y, o; kw...)
#     @test all(value(o) .≈ f(y))
# end

# # test: fo(o) == fy(y)
# function test_function(o, y, fo, fy; atol = 1e-10)
#     @inferred Series(y, o)
#     @test all(isapprox.(fo(o), fy(y), atol = atol))
# end

#-----------------------------------------------------------------------# Show
info("Show")
for o = [Mean(), Variance(), CStat(Mean()), CovMatrix(5), Diff(), Extrema(), 
         HyperLogLog(4), Moments(), OrderStats(10), Quantile(), PQuantile(),
         ReservoirSample(10), Sum(), StatLearn(5), 
         LinRegBuilder(5), LinReg(5), CallFun(Mean(), info), Bootstrap(Mean())]
    println(o)
    typeof(o) <: OnlineStat{0} && println(2o)
end
println(Series(Mean()))
println(Series(Mean(), Variance(), Moments()))
println(25Mean())
Series(randn(2), CallFun(Mean(), x -> println("this should print twice")))

println("\n\n")

#-----------------------------------------------------------------------# Data
y = randn(100)
y2 = randn(100)
x = randn(100, 5)
x2 = randn(100, 5)

#-----------------------------------------------------------------------# merge stats
@testset "test_merge 0" begin 
    for o in [Mean(), Variance(), CStat(Mean()), Extrema(), HyperLogLog(10), Moments(),
              OrderStats(5), Sum()]
        test_merge(o, copy(o), y, y2)
    end
    test_merge(OrderStats(5), OrderStats(5), rand(6), rand(6))

    # merge! with weight
    s = Series([1], Mean())
    merge!(s, Series([2], Mean()))
    @test value(s)[1] == 1.5
end
@testset "test_merge 1" begin 
    for o in [5Mean(), 5Variance(), CovMatrix(5), LinRegBuilder(5)]
        test_merge(o, copy(o), x, x2)
    end
end
@testset "test_merge (1,0)" begin 
    for o in [LinReg(5), StatLearn(5)]
        test_merge(o, copy(o), (x,y), (x2, y2))
    end
end


#-----------------------------------------------------------------------# Series
@testset "Series" begin 
@testset "Constructors" begin
    @test Series(EqualWeight(), Mean()) == Series(Mean())
    @test Series(y, Mean()) == Series(EqualWeight(), y, Mean())
    @test Series(y, Mean()) == Series(y, EqualWeight(), Mean())
    s = Series(Mean())
    fit!(s, y)
    @test s == Series(y, Mean())
end
@testset "fit! 0" begin 
    s = Series(Mean())
    @test value(s)[1] == mean(stats(s)[1])
    # single observation
    fit!(s, y[1])
    @test value(s)[1] ≈ y[1]
    # multiple observations
    fit!(s, y[2:10])
    @test value(s)[1] ≈ mean(y[1:10])
    # single observation, override weight
    s = Series(Mean())
    fit!(s, y[1], .1)
    @test value(s)[1] ≈ .1 * y[1]
    # multiple observation, override weight 
    s = Series(Mean())
    fit!(s, y[1:2], .1)
    @test value(s)[1] ≈ .1 * .9 * y[1] + .1 * y[2]
    # multiple observation, override weights 
    s = Series(Mean())
    fit!(s, y[1:2], [.1, .2])
    @test value(s)[1] ≈ .1 * .8 * y[1] + .2 * y[2]
    @testset "allocations" begin 
        # run once to compile
        Series(y, Mean())
        Series(y, ExponentialWeight(), Mean())
        Series(ExponentialWeight(), y, Mean())

        @test @allocated(Series(y, Mean())) < 300
        @test @allocated(Series(y, ExponentialWeight(), Mean())) < 300
        @test @allocated(Series(ExponentialWeight(), y, Mean())) < 300
    end
end
@testset "fit! 1" begin 
    # single observation
    s = Series(MV(5, Mean()))
    fit!(s, x[1, :])
    @test value(s)[1] ≈ x[1, :]
    # multiple observations
    fit!(s, x[2:10, :])
    @test value(s)[1] ≈ vec(mean(x[1:10, :], 1))
    # single observation, override weight
    s = Series(MV(5, Mean()))
    fit!(s, x[1, :], .1)
    @test value(s)[1] ≈ .1 .* x[1, :]
    # multiple observations, override weight 
    s = Series(MV(5, Mean()))
    fit!(s, x[1:2, :], .1)
    @test value(s)[1] ≈ .1 .* .9 .* x[1,:] + .1 .* x[2,:]
    # multiple observations, override weights
    s = Series(MV(5, Mean()))
    fit!(s, x[1:2, :], [.1, .2])
    @test value(s)[1] ≈ .1 .* .8 .* x[1,:] + .2 * x[2,:]
    @testset "column observations" begin 
        # normal
        s = Series(CovMatrix(5))
        fit!(s, x', Cols())
        @test s == Series(x, CovMatrix(5))
        # weight override
        s = Series(CovMatrix(5))
        s2 = Series(CovMatrix(5))
        fit!(s, x, .1)
        fit!(s2, x', .1, Cols())
        @test s == s2
        # weights override
        w = rand(100)
        s = Series(CovMatrix(5))
        s2 = Series(CovMatrix(5))
        fit!(s, x, w)
        fit!(s2, x', w, Cols())
        @test s == s2
    end
    @testset "allocated" begin 
        Series(x, MV(5, Mean()))
        Series(x, ExponentialWeight(), MV(5, Mean()))
        Series(ExponentialWeight(), x, MV(5, Mean()))

        @test @allocated(Series(x, MV(5, Mean()))) < 800
        @test @allocated(Series(x, ExponentialWeight(), MV(5, Mean()))) < 800
        @test @allocated(Series(ExponentialWeight(), x, MV(5, Mean()))) < 800
    end
end
@testset "fit! (1,0)" begin 
    # single observation
    s = Series(LinReg(5))
    fit!(s, (randn(5), randn()))
    # single observation, override weight 
    s = Series(LinReg(5))
    fit!(s, (randn(5), rand()), .1)
    # multiple observations
    s = Series(LinReg(5))
    fit!(s, (x, y))
    @test value(s)[1] ≈ x\y
    # multiple observations, by column
    s = Series(LinReg(5))
    fit!(s, (x', y), Cols())
    @test value(s)[1] ≈ x\y
    # multiple observations, override weight
    s = Series(LinReg(5))
    fit!(s, (x, y), .1)
    s = Series(LinReg(5))
    fit!(s, (x', y), .1, Cols())
    # multiple observaitons, override weights 
    fit!(s, (x, y), rand(length(y)))
    fit!(s, (x', y), rand(length(y)), Cols())
end
@testset "merging" begin 
    @test merge(Series(Mean()), Series(Mean())) == Series(Mean())
    s1 = merge(Series(y, Mean()), Series(y2, Mean()))
    s2 = Series(vcat(y,y2), Mean())
    @test value(s1)[1] ≈ value(s2)[1]
    @test_throws Exception merge(Series(y, Mean()), Series(y, Mean()), 100.0)
    merge(s1, s2, :mean)
    merge(s1, s2, :singleton)
    @test_throws Exception merge(s1, s2, :fakemethod)

    s1 = Series(y, Mean())
    s2 = Series(y2, Mean())
    merge!(s1, s2)
    @test value(stats(s1)[1]) ≈ mean(vcat(y, y2))
    @test_throws ErrorException merge(Series(Mean()), Series(Variance()))
end
end #Series

#-----------------------------------------------------------------------# mapblocks
@testset "mapblocks" begin 
    x = randn(10, 5)
    o = CovMatrix(5)
    s = Series(o)
    mapblocks(3, x, Rows()) do xi
        fit!(s, xi)
    end
    i = 0
    mapblocks(2, x, Cols()) do xi 
        i += 1
    end
    @test i == 3
    @test cov(o) ≈ cov(x)
    i = 0
    mapblocks(3, rand(5)) do xi
        i += 1
    end
    @test i == 2
    s = Series(LinReg(5))
    x, y = randn(100, 5), randn(100)
    mapblocks(11, (x, y)) do xy
        fit!(s, xy)
    end
    @test value(s)[1] ≈ x\y
    @test_throws Exception mapblocks(info, (randn(100,5), randn(3)))
end

#-----------------------------------------------------------------------# Quantile
@testset "Quantile/PQuantile" begin 
    y = randn(10_000)
    for o in [Quantile(.1:.1:.9, SGD()), Quantile(.1:.1:.9, MSPI()), 
              Quantile(.1:.1:.9, OMAS())]
        Series(y, o)
        @test value(o) ≈ quantile(y, .1:.1:.9) atol=.2
        # merging
        o2 = copy(o)
        merge!(o, copy(o), .5)
        @test value(o) ≈ value(o2)
    end
    for τ in .1:.1:.9 
        o = PQuantile(τ)
        Series(y, o)
        @test quantile(y, τ) ≈ value(o) atol=.02
    end
end

#-----------------------------------------------------------------------# Tests
@testset "Distributions" begin
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
        test_merge(FitBeta(), FitBeta(), rand(50), rand(50))
    end
    @testset "FitCategorical" begin
        y = rand(1:5, 1000)
        o = FitCategorical(Int)
        s = Series(y, o)
        for i in 1:5
            @test i in keys(o)
        end
        vals = ["small", "big"]
        s = Series(rand(vals, 100), FitCategorical(String))
        value(s)

        @test keys(o) == keys(o.d)
        @test values(o) == values(o.d)
        test_merge(FitCategorical(Int), FitCategorical(Int), y, rand(1:2, 10))
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
        test_merge(FitGamma(), FitGamma(), rand(100) + 5, rand(100) + 5)
    end
    @testset "FitLogNormal" begin
        o = FitLogNormal()
        @test value(o) == (0.0, 1.0)
        Series(exp.(randn(100)), o)
        @test value(o)[1] != 0
        @test value(o)[2] > 0
        test_merge(FitLogNormal(), FitLogNormal(), exp.(randn(100)), exp.(randn(100)))
    end
    @testset "FitNormal" begin
        o = FitNormal()
        @test value(o) == (0.0, 1.0)
        y = randn(100)
        Series(y, o)
        @test value(o)[1] ≈ mean(y)
        @test value(o)[2] ≈ std(y)
        test_merge(FitNormal(), FitNormal(), randn(100), randn(100))
    end
    @testset "FitMultinomial" begin
        o = FitMultinomial(5)
        @test value(o)[2] == ones(5) / 5
        s = Series([1,2,3,4,5], o)
        fit!(s, [1, 2, 3, 4, 5])
        @test value(o)[2] == [1, 2, 3, 4, 5] ./ 15
        test_merge(FitMultinomial(3), FitMultinomial(3), [1,2,3], [2,3,4])
    end
    @testset "FitMvNormal" begin
        y = randn(1000, 3)
        o = FitMvNormal(3)
        @test value(o) == (zeros(3), eye(3))
        @test length(o) == 3
        s = Series(y, o)
        @test value(o)[1] ≈ vec(mean(y, 1))
        @test value(o)[2] ≈ cov(y)
        test_merge(FitMvNormal(3), FitMvNormal(3), randn(10,3), randn(10,3))
    end
end

@testset "StatLearn" begin
    n, p = 1000, 10
    x = randn(n, p)
    y = x * linspace(-1, 1, p) + .5 * randn(n)

    for u in [SGD(), NSGD(), ADAGRAD(), ADADELTA(), RMSPROP(), ADAM(), ADAMAX(), NADAM(), 
              MSPI(), OMAP(), OMAS()]
        o = @inferred StatLearn(p, .5 * L2DistLoss(), L2Penalty(), fill(.1, p), u)
        s = @inferred Series(o)
        @test value(o, x, y) == value(.5 * L2DistLoss(), y, zeros(y), AvgMode.Mean())
        fit!(s, (x, y))
        fit!(s, (x, y), .1)
        fit!(s, (x, y), StatsBase.Weights(rand(length(y))))
        @test nobs(s) == 3 * n
        @test coef(o) == o.β
        @test predict(o, x) == x * o.β
        @test predict(o, x', Cols()) ≈ x * o.β
        @test predict(o, x[1,:]) == x[1,:]'o.β
        @test loss(o, x, y) == value(o.loss, y, predict(o, x), AvgMode.Mean())

        # sanity check for merge!
        merge!(StatLearn(4, u), StatLearn(4, u), .5)

        o = StatLearn(p, LogitMarginLoss())
        o.β[:] = ones(p)
        @test classify(o, x) == sign.(vec(sum(x, 2)))

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
    end
    @testset "MM-based" begin
        x, y = randn(100, 5), randn(100)
        @test_throws ErrorException Series((x,y), StatLearn(5, PoissonLoss(), OMAS()))
    end
end
@testset "LinRegBuilder" begin
    n, p = 100, 10
    x = randn(n, p)
    o = LinRegBuilder(p)
    Series(x, o)
    for k in 1:p
        @test coef(o; y=k, verbose=false) ≈ [x[:, setdiff(1:p, k)] ones(n)] \ x[:, k]
    end
    @test coef(o; y=3, x=[1, 2], verbose=false, bias=false) ≈ x[:, [1, 2]] \ x[:, 3]
    @test coef(o; y=3, x=[2, 1], verbose=false, bias=false) ≈ x[:, [2, 1]] \ x[:, 3]
    @test coef(o) == value(o)
end
@testset "CovMatrix" begin 
    x = randn(100, 5)
    o = CovMatrix(5)
    Series(x, o)
    @test var(o) ≈ vec(var(x, 1))
    @test std(o) ≈ vec(std(x, 1))
    @test mean(o) ≈ vec(mean(x, 1))
    @test cor(o) ≈ cor(x)
end
@testset "Extrema" begin 
    o = Extrema()
    Series(y, o)
    @test extrema(o)[1] == extrema(y)[1]
    @test extrema(o)[2] == extrema(y)[2]
end
@testset "Moments" begin 
    o = Moments()
    Series(y, o)
    @test mean(o) ≈ mean(y)
    @test var(o) ≈ var(y) 
    @test std(o) ≈ std(y)
    @test skewness(o) ≈ skewness(y) atol=.1
    @test kurtosis(o) ≈ kurtosis(y) atol=.1
end
@testset "LinReg" begin 
    o = LinReg(5)
    @test nobs(o) == 0
    x, y = randn(100,5), randn(100)
    s = Series((x,y), o)
    @test nobs(o) == 100
    @test coef(o) ≈ x\y
    @test predict(o, x) ≈ x * (x\y)
    @test predict(o, x', Cols()) ≈ x * (x\y)
    o2 = LinReg(5)
    s2 = Series((x,y), o2)
    @test LinReg(5, .1) == LinReg(5, fill(.1, 5))
    @test predict(o2, zeros(5)) == 0.0
    # check both fit! methods
    o = LinReg(5)
    fit!(o, (randn(5), randn()), .1)
    fit!(o, randn(5), randn(), .1)
end
@testset "IHistogram" begin
    y = rand(1000)
    o = IHistogram(100)
    Series(y, o)
    for val in value(o)
        @test 0 < val < 1
    end
    @test sum(o.counts) == 1000

    o2 = IHistogram(50)
    Series(rand(1000), o2)

    merge!(o, o2, .1)
    @test sum(o.counts) == 2000
    @test median(o) ≈ median(y) atol=.1
    @test var(o) ≈ var(y) atol=.1
    @test std(o) ≈ std(y) atol=.1
    @test mean(o) ≈ mean(y) atol=.1
    o = IHistogram(25)
    y = 1:25
    Series(y, o)
    @test extrema(o) == extrema(y)
    @test quantile(o) ≈ quantile(y) atol=.1
end
@testset "OHistogram" begin 
    y = randn(100)
    o = OHistogram(-5:.01:5)
    Series(y, o)
    @test mean(o) ≈ mean(y) atol=.1
    @test var(o) ≈ var(y) atol=.1
    @test std(o) ≈ std(y) atol=.1
    @test quantile(o) ≈ quantile(y) atol=.1
end
@testset "Other" begin 
    o = Variance()
    @test nobs(o) == 0
    Series(y, o)
    @test nobs(o) == length(y)
    @test length(5Mean()) == 5
    @test sum(Sum()) == 0
end
@testset "Diff" begin 
    o = Diff(Int)
    Series([1,2], o)
    @test diff(o) == 1
    @test last(o) == 2
    o = Diff(Float64)
    Series([1,2], o)
    @test diff(o) == 1
    @test last(o) == 2
end
@testset "ReservoirSample" begin 
    o = ReservoirSample(100)
    Series(y, o)
    @test value(o) == y
    o = ReservoirSample(10)
    Series(y, o)
    for yi in value(o)
        @test yi in y 
    end
end
@testset "Bootstrap" begin 
    o = Bootstrap(Mean(), 100, [1])
    Series(y, o)
    for ybar in value(o)
        @test ybar == value(o.o)
    end
    @test length(confint(o)) == 2
    o.replicates[1].μ = NaN
    @test isnan(confint(o)[1])
    @test isnan(confint(o)[2])
end
@testset "KMeans" begin 
    o = KMeans(5, 4)
    Series(randn(100, 5), o)
end
end #module
