module OnlineStatsTest

using OnlineStats, Base.Test
import StatsBase

#-----------------------------------------------------------------------# helpers
# test: merge is same as fit!
function test_merge(o1, o2, y1, y2)
    s1 = @inferred Series(y1, o1)
    s2 = Series(y2, o2)
    merge!(s1, s2)
    fit!(s2, y1)
    @test value(o1) == value(o1)
end

# test: value(o) == f(y)
function test_exact(o, y, f; kw...)
    s = @inferred Series(y, o; kw...)
    @test all(value(o) .≈ f(y))
end

# test: fo(o) == fy(y)
function test_function(o, y, fo, fy; atol = 1e-10)
    @inferred Series(y, o)
    @test all(isapprox.(fo(o), fy(y), atol = atol))
end

#-----------------------------------------------------------------------# Show

@show StatLearn(5)
@show LinearModels(5)

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
        Series(rand(100), o)
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

    for u in [SGD(), NSGD(), ADAGRAD(), ADADELTA(), RMSPROP(), ADAM(), ADAMAX(), NADAM(), OMAPQ(),
            OMASQ(), MSPIQ()]
        o = @inferred StatLearn(p, .5 * L2DistLoss(), L2Penalty(), fill(.1, p), u)
        s = @inferred Series(o)
        @test objective(o, x, y) == value(.5 * L2DistLoss(), y, zeros(y), AvgMode.Mean())
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
        @test_throws ErrorException Series((x,y), StatLearn(5, PoissonLoss(), OMASQ()))
    end
end
@testset "LinearModels" begin
    x = randn(100, 5)
    o = LinearModels(5)
    Series(x, o)
    for k in 1:5
        @test coef(o, k) ≈ x[:, setdiff(1:5, k)] \ x[:, k]
    end
end
end #module
