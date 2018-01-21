println()
println()
info("Testing Stats:")
#-----------------------------------------------------------------------# AutoCov
@testset "AutoCov" begin 
    test_exact(AutoCov(10), y, autocov, x -> autocov(x, 0:10))
    test_exact(AutoCov(10), y, autocor, x -> autocor(x, 0:10))
    test_exact(AutoCov(10), y, nobs, length)
end
#-----------------------------------------------------------------------# Bootstrap 
@testset "Bootstrap" begin 
    o = Bootstrap(Mean(), 100, [1])
    Series(y, o)
    @test all(value.(o.replicates) .== value(o))
    @test length(confint(o)) == 2
end
#-----------------------------------------------------------------------# Count 
@testset "Count" begin 
    test_exact(Count(), randn(100), value, length)
    test_merge(Count(), rand(100), rand(100), ==)
end
#-----------------------------------------------------------------------# CountMap
@testset "CountMap" begin
    test_exact(CountMap(Int), rand(1:10, 100), nobs, length, ==)
    test_exact(CountMap(Int), rand(1:10, 100), value, countmap, ==)
    test_merge(CountMap(Bool), rand(Bool, 100), rand(Bool, 100), ==)
    test_merge(CountMap(Bool), trues(100), falses(100), ==)
    test_merge(CountMap(Int), rand(1:4, 100), rand(5:123, 50), ==)
end
#-----------------------------------------------------------------------# CovMatrix
@testset "CovMatrix" begin 
    test_exact(CovMatrix(5), x, var, x -> vec(var(x, 1)))
    test_exact(CovMatrix(5), x, std, x -> vec(std(x, 1)))
    test_exact(CovMatrix(5), x, mean, x -> vec(mean(x, 1)))
    test_exact(CovMatrix(5), x, cor, cor)
    test_exact(CovMatrix(5), x, cov, cov)
    test_exact(CovMatrix(5), x, o->cov(o;corrected=false), x->cov(x,1,false))
    test_merge(CovMatrix(5), x, x2)
end
#-----------------------------------------------------------------------# CStat 
@testset "CStat" begin 
    test_merge(CStat(Mean()), y, y2)
end
#-----------------------------------------------------------------------# Extrema
@testset "Extrema" begin 
    test_exact(Extrema(), y, extrema, extrema, ==)
    test_exact(Extrema(), y, maximum, maximum, ==)
    test_exact(Extrema(), y, minimum, minimum, ==)
    test_merge(Extrema(), y, y2, ==)
end
#-----------------------------------------------------------------------# Distributions
@testset "Fit[Distribution]" begin
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
        test_exact(FitBeta(), rand(500), value, x->[1,1], (a,b) -> ≈(a,b;atol=.3))
        test_merge(FitBeta(), rand(50), rand(50))
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
        test_merge(FitGamma(), rand(100) + 5, rand(100) + 5)
    end
    @testset "FitLogNormal" begin
        o = FitLogNormal()
        @test value(o) == (0.0, 1.0)
        Series(exp.(randn(100)), o)
        @test value(o)[1] != 0
        @test value(o)[2] > 0
        test_merge(FitLogNormal(), exp.(randn(100)), exp.(randn(100)))
    end
    @testset "FitNormal" begin
        o = FitNormal()
        @test value(o) == (0.0, 1.0)
        Series(y, o)
        @test value(o)[1] ≈ mean(y)
        @test value(o)[2] ≈ std(y)
        test_merge(FitNormal(), randn(100), randn(100))
    end
    @testset "FitMultinomial" begin
        o = FitMultinomial(5)
        @test value(o)[2] == ones(5) / 5
        s = Series([1,2,3,4,5], o)
        fit!(s, [1, 2, 3, 4, 5])
        @test value(o)[2] == [1, 2, 3, 4, 5] ./ 15
        test_merge(FitMultinomial(3), [1,2,3], [2,3,4])
    end
    @testset "FitMvNormal" begin
        data = randn(1000, 3)
        o = FitMvNormal(3)
        @test value(o) == (zeros(3), eye(3))
        @test length(o) == 3
        s = Series(data, o)
        @test value(o)[1] ≈ vec(mean(data, 1))
        @test value(o)[2] ≈ cov(data)
        test_merge(FitMvNormal(3), randn(10,3), randn(10,3))
    end
end
#-----------------------------------------------------------------------# Group 
@testset "Group" begin 
    o = [Mean() Mean() Mean() Variance() Variance()]
    test_exact(o, x, value, x -> vcat(mean(x,1)[1:3], var(x,1)[4:5]))
    test_merge([Mean() Variance() Sum() Moments() Mean()], x, x2)
end
#-----------------------------------------------------------------------# Hist 
@testset "Hist" begin
    test_exact(Hist(-5:5), y, o -> value(o)[2], y -> fit(Histogram, y, -5:5, closed=:left).weights)
    test_exact(Hist(-5:.1:5), y, extrema, extrema, (a,b)->≈(a,b;atol=.2))
    test_exact(Hist(-5:.1:5), y, mean, mean, (a,b)->≈(a,b;atol=.2))
    test_exact(Hist(-5:.1:5), y, var, var, (a,b)->≈(a,b;atol=.2))
    test_merge(Hist(-5:.1:5), y, y2)

    test_exact(Hist(100), y, mean, mean)
    test_exact(Hist(100), y, var, var)
    test_exact(Hist(100), y, extrema, extrema, ==)
    test_merge(Hist(200), y, y2)
    test_merge(Hist(1), y, y2)
end
#-----------------------------------------------------------------------# LinReg 
@testset "LinReg" begin 
    test_exact(LinReg(5), (x,y), coef, xy -> xy[1]\xy[2])
    test_merge(LinReg(5), (x,y), (x2,y2))
end
#-----------------------------------------------------------------------# LinRegBuilder 
@testset "LinRegBuilder" begin 
    test_exact(LinRegBuilder(6), [x y], o -> coef(o;bias=false,y=6), f -> x\y)
    test_merge(LinRegBuilder(5), x, x2)
end
#-----------------------------------------------------------------------# Mean 
@testset "Mean" begin 
    test_exact(Mean(), y, mean, mean)
    test_merge(Mean(), y, y2)
end
#-----------------------------------------------------------------------# Moments
@testset "Moments" begin 
    test_exact(Moments(), y, value, x ->[mean(x), mean(x .^ 2), mean(x .^ 3), mean(x .^4) ])
    test_exact(Moments(), y, skewness, skewness, (a,b) -> ≈(a,b,atol=.1))
    test_exact(Moments(), y, kurtosis, kurtosis, (a,b) -> ≈(a,b,atol=.1))
    test_exact(Moments(), y, mean, mean)
    test_exact(Moments(), y, var, var)
    test_exact(Moments(), y, std, std)
    test_merge(Moments(), y, y2)
end
#-----------------------------------------------------------------------# MV 
@testset "MV" begin 
    o = MV(5, Mean())
    @test length(o) == 5
    test_exact(5Mean(), x, value, x->vec(mean(x,1)))
    test_merge(5Mean(), x, x2)
    test_exact(5Variance(), x, value, x->vec(var(x,1)))
    test_merge(5Variance(), x, x2)
end
#-----------------------------------------------------------------------# Quantile
@testset "Quantile/PQuantile" begin 
    data = randn(10_000)
    data2 = randn(10_000)
    τ = .1:.1:.9
    for o in [Quantile(τ, SGD()), Quantile(τ, MSPI()), Quantile(τ, OMAS())]
        test_exact(o, data, value, x -> quantile(x,τ), (a,b) -> ≈(a,b,atol=.25))
        test_merge(o, data, data2, (a,b) -> ≈(a,b,atol=.25))
    end
end

#-----------------------------------------------------------------------# StatLearn
@testset "StatLearn" begin
    n, p = 1000, 10
    X = randn(n, p)
    Y = X * linspace(-1, 1, p) + .5 * randn(n)

    for u in [SGD(), NSGD(), ADAGRAD(), ADADELTA(), RMSPROP(), ADAM(), ADAMAX(), NADAM(), 
              MSPI(), OMAP(), OMAS()]
        o = @inferred StatLearn(p, .5 * L2DistLoss(), L2Penalty(), fill(.1, p), u)
        s = @inferred Series(o)
        @test value(o, X, Y) == value(.5 * L2DistLoss(), Y, zeros(Y), AvgMode.Mean())
        fit!(s, (X, Y))
        @test nobs(s) == n
        @test coef(o) == o.β
        @test predict(o, X) == X * o.β
        @test predict(o, X', Cols()) ≈ X * o.β
        @test predict(o, X[1,:]) == X[1,:]'o.β
        @test loss(o, X, Y) == value(o.loss, Y, predict(o, X), AvgMode.Mean())

        # sanity check for merge!
        merge!(StatLearn(4, u), StatLearn(4, u), .5)

        o = StatLearn(p, LogitMarginLoss())
        o.β[:] = ones(p)
        @test classify(o, X) == sign.(vec(sum(X, 2)))

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
        X, Y = randn(100, 5), randn(100)
        @test_throws ErrorException Series((X,Y), StatLearn(5, PoissonLoss(), OMAS()))
    end
end
#-----------------------------------------------------------------------# Variance 
@testset "Variance" begin 
    test_exact(Variance(), y, mean, mean)
    test_exact(Variance(), y, std, std)
    test_exact(Variance(), y, var, var)
    test_merge(Variance(), y, y2)
end