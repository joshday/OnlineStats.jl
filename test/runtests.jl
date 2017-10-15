module OnlineStatsTest

using OnlineStats, Base.Test
import StatsBase

@show StatLearn(5)


@testset "mapblocks" begin
    for o = [randn(6), randn(6,2), (randn(7,2), randn(7))]
        i = 0
        mapblocks(5, o) do x
            i += 1
        end
        @test i == 2
    end

    # (1, 0) input
    s = Series(StatLearn(5))
    x, y = randn(100,5), randn(100)
    mapblocks(10, (x,y)) do xy
        fit!(s, xy)
    end
    s2 = Series((x,y), StatLearn(5))
    @test nobs(s2) == nobs(s)
    @test s == s2

    s3 = Series(StatLearn(5))
    mapblocks(11, (x', y), Cols()) do xy
        fit!(s3, xy, Cols())
    end
    @test nobs(s3) == 100
    @test all(value(s) .≈ value(s3))

    # 1 input
    s4 = Series(CovMatrix(5))
    mapblocks(11, x) do xi
        fit!(s4, xi)
    end
    s5 = Series(CovMatrix(5))
    mapblocks(11, x', Cols()) do xi
        fit!(s5, xi, Cols())
    end
    @test s4 == s5

    @test_throws Exception mapblocks(sum, 10, (x,y), Cols())
end

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
        Series(rand(100), o)
        @test value(o)[1] ≈ 1.0 atol=.4
        @test value(o)[2] ≈ 1.0 atol=.4
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
    end
    @testset "FitCauchy" begin
        o = FitCauchy()
        @test value(o) == (0.0, 1.0)
        Series(randn(100), o)
        @test value(o) != (0.0, 1.0)
    end
    @testset "FitGamma" begin
        o = FitGamma()
        @test value(o) == (1.0, 1.0)
        Series(rand(100) + 5, o)
        @test value(o)[1] > 0
        @test value(o)[2] > 0
    end
    @testset "FitLogNormal" begin
        o = FitLogNormal()
        @test value(o) == (0.0, 1.0)
        Series(exp.(randn(100)), o)
        @test value(o)[1] != 0
        @test value(o)[2] > 0
    end
    @testset "FitNormal" begin
        o = FitNormal()
        @test value(o) == (0.0, 1.0)
        y = randn(100)
        Series(y, o)
        @test value(o)[1] ≈ mean(y)
        @test value(o)[2] ≈ std(y)
    end
    @testset "FitMultinomial" begin
        o = FitMultinomial(5)
        @test value(o)[2] == ones(5) / 5
        s = Series([1,2,3,4,5], o)
        fit!(s, [1, 2, 3, 4, 5])
        @test value(o)[2] == [1, 2, 3, 4, 5] ./ 15
    end
    @testset "FitMvNormal" begin
        y = randn(1000, 3)
        o = FitMvNormal(3)
        @test value(o) == (zeros(3), eye(3))
        @test length(o) == 3
        s = Series(y, o)
        @test value(o)[1] ≈ vec(mean(y, 1))
        @test value(o)[2] ≈ cov(y)
    end
end

@testset "StatLearn" begin
    n, p = 1000, 10
    x = randn(n, p)
    y = x * linspace(-1, 1, p) + .5 * randn(n)

    for u in [SGD(), NSGD(), ADAGRAD(), ADADELTA(), RMSPROP(), ADAM(), ADAMAX(), NADAM(), OMAPQ(),
            OMASQ(), MSPIC()]
        o = @inferred StatLearn(p, .5 * L2DistLoss(), L2Penalty(), fill(.1, p), u)
        s = @inferred Series(o)
        fit!(s, (x, y))
        fit!(s, (x, y), .1)
        fit!(s, (x, y), StatsBase.Weights(rand(length(y))))
        @test nobs(s) == 3 * n
        @test coef(o) == o.β
        @test predict(o, x) == x * o.β
        @test predict(o, x', Cols()) ≈ x * o.β
        @test predict(o, x[1,:]) == x[1,:]'o.β
        @test loss(o, x, y) == value(o.loss, y, predict(o, x), AvgMode.Mean())

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
end
end
