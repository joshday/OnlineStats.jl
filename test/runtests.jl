module OnlineStatsTest
using OnlineStats, Base.Test, Distributions

#-----------------------------------------------------------# coverage for show() methods
info("Messy output for test coverage")
@testset "show" begin
    println(Series(Mean()))
    println(Bootstrap(Series(Mean()), 100, Poisson()))
    println(OnlineStats.name(Moments(), false))
    println(Mean())
    println(Variance())
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
    @testset "maprows" begin
        s = Series(Mean(), Variance())
        y = randn(100)
        maprows(10, y) do yi
            fit!(s, yi)
            print("$(nobs(s)), ")
        end
        println()
        @test nobs(s) == 100
        @test value(s, 1) ≈ mean(y)
        @test value(s, 2) ≈ var(y)
    end
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

    for w in [w1, w3, w4, w5]
        @test OnlineStats.weight!(w, 1) == 1
    end
    for i in 1:10
        @test OnlineStats.weight(w1) == 1 / i
        @test OnlineStats.weight(w2) == w2.λ
        @test OnlineStats.weight(w3) == 1 / i
        @test OnlineStats.weight(w4) ≈ i ^ -w4.r
        @test OnlineStats.weight(w5) ≈ 1 / (1 + w5.c * (i-1))
        map(OnlineStats.updatecounter!, [w1, w2, w3, w4, w5])
    end
    # @test OnlineStats.weight(w3, 1_000_000, 1, 1_000_000) == w3.λ

    @inferred ExponentialWeight(100)
    @inferred BoundedEqualWeight(100)

    @test EqualWeight() == EqualWeight()
    @test LearningRate() == LearningRate()
    @test nups(EqualWeight()) == 0
end
#-----------------------------------------------------------------------------# Series
@testset "Series" begin
    @test_throws ArgumentError Series(Mean(), CovMatrix(3))
    @test_throws ArgumentError Series(Mean(), QuantileMM())
    @testset "Type-stable Constructors" begin
         @inferred Series(EqualWeight(), Mean(), Variance())
         @inferred Series(EqualWeight(), Mean())
         @inferred Series(Mean())
         @inferred Series(Mean(), Variance())
         @inferred Series((Mean(), Variance()))
         @inferred Series(randn(100), Mean(), Variance())
         @inferred Series(randn(100), Mean())
         @inferred Series(randn(100), EqualWeight(), Mean(), Variance())
         @inferred Series(randn(100), EqualWeight(), Mean())
    end
    @testset "fit!" begin
        s = Series(Mean(), Sum())
        fit!(s, rand())
        fit!(s, rand(99))
        @test nobs(s) == 100
        fit!(s, randn(100), .01)
        fit!(s, randn(100), rand(100))
        @test nobs(s) == 300
        fit!(s, randn(100), 7)
        @test nobs(s) == 400

        s = Series(CovMatrix(3))
        fit!(s, randn(3))
        fit!(s, randn(99, 3))
        fit!(s, randn(100, 3), .01)
        fit!(s, randn(100, 3), rand(100))
        fit!(s, randn(100, 3), 7)
        @test nobs(s) == 400
    end
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

@testset "Series merge" begin
    y1 = randn(100)
    y2 = randn(100)
    y = vcat(y1, y2)
    o1 = @inferred Series(Mean(), Variance())
    o2 = @inferred Series(Mean(), Variance())
    fit!(o1, y1)
    fit!(o2, y2)

    o3 = merge(o1, o2)
    @test value(o3, 1) ≈ mean(y)
    @test value(o3, 2) ≈ var(y)

    merge(o1, o2, :mean)
    merge(o1, o2, :singleton)
    @test_throws ArgumentError merge(o1, o2, :not_a_real_method)
    @inferred merge(Mean(), Mean(), .1)

    s1 = Series(y1, Moments())
    s2 = Series(y2, Moments())
    s3 = merge(s1, s2)
    @test mean(s3.stats) ≈ mean(vcat(y1, y2))
end

moments(y) = [mean(y), mean(y.^2), mean(y.^3), mean(y.^4)]
@testset "Summary" begin
    y1 = randn(500)
    y2 = randn(501)
    y = vcat(y1, y2)
    for (f, o) in zip([mean, var, extrema, sum, moments],
                      [Mean(), Variance(), Extrema(), Sum(), Moments()])
        @testset "$(typeof(o))" begin
            s = Series(o)
            y = randn(100)
            fit!(s, y)
            @test all(value(o) .≈ f(y))
        end
    end
    @testset "QuantileMM/QuantileSGD" begin
        o = QuantileMM(.2, .3)
        s = @inferred Series(y1, o, QuantileSGD([.4, .5]))
        @test typeof(s.weight) == LearningRate
        fit!(s, y2, 7)
    end
    @testset "Extra methods" begin
        @test mean(Mean()) == 0.0
        @test nobs(Variance()) == 0
        @test extrema(Extrema()) == (Inf, -Inf)

        y = randn(10000)
        o = Moments()
        s = Series(y, o)
        @test mean(o) ≈ mean(y)
        @test var(o) ≈ var(y)
        @test std(o) ≈ std(y)
        @test kurtosis(o) ≈ kurtosis(y) atol = .1
        @test skewness(o) ≈ skewness(y) atol = .1

        QuantileSGD(.4, .5)
    end
end

@testset "Distributions" begin
    @testset "Distribution params" begin
        function testdist(d::Symbol, wt = EqualWeight(), tol = 1e-4)
            y = @eval rand($d(), 10_000)
            o = @eval $(Symbol(:Fit, d))()
            @test value(o) == @eval($d())
            s = Series(y, wt, o)
            fit!(s, y)
            myfit = @eval fit($d, $y)
            for i in 1:length(params(o))
                @test params(o)[i] ≈ params(myfit)[i] atol = tol
            end
        end
        testdist(:Beta)
        testdist(:Cauchy, LearningRate(), .1)
        testdist(:Gamma, EqualWeight(), .1)
        testdist(:LogNormal)
        testdist(:Normal)
    end
    @testset "FitCategorical" begin
        y = rand(1:5, 1000)
        o = FitCategorical(Int)
        s = Series(y, o)
        myfit = fit(Categorical, y)
        pr = probs(value(o))
        for i in eachindex(pr)
            @test pr[i] in probs(myfit)
        end
        for i in 1:5
            @test i in keys(o)
        end
    end
    @testset "FitMultinomial" begin
        y = rand(Multinomial(10, ones(5) / 5), 1000)
        myfit = fit(Multinomial, y)
        o = FitMultinomial(5)
        @test params(value(o)) == (1, ones(5) / 5)
        s = Series(o)
        fit!(s, y')
        @test probs(o) ≈ probs(myfit)
    end
    @testset "FitMvNormal" begin
        y = rand(MvNormal(zeros(3), eye(3)), 1000)
        myfit = fit(MvNormal, y)
        o = FitMvNormal(3)
        @test length(o) == 3
        @test params(value(o))[1] == zeros(3)
        s = Series(y', o)
        @test mean(o) ≈ mean(myfit)
    end
    @testset "NormalMix" begin
        d = MixtureModel([Normal(), Normal(1,2), Normal(2, 3)])
        y = rand(d, 1000)
        o = NormalMix(3, y)
        s = Series(y, o)
        fit!(s, y, 10)
        components(o)
        @test isa(component(o, 1), Normal)
        component(o, 2)
        component(o, 3)
        @test ncomponents(o) == 3
    end
end
@testset "HyperLogLog" begin
    o = HyperLogLog(10)
    for d in 4:16
        o = HyperLogLog(d)
        @test value(o) == 0.0
        s = Series(o)
        fit!(s, rand(1:10, 1000))
        @test 8 < value(o) < 12
    end
    @test_throws Exception HyperLogLog(1)
end
@testset "CovMatrix" begin
    x = randn(100, 5)
    o = CovMatrix(5)
    s = Series(x, o)
    @test nobs(s) == 100
    fit!(s, x, 10)
    OnlineStats.fitbatch!(o, x, .1)

    o = CovMatrix(5)
    s = Series(o)
    fit!(s, x, 10)
    @test mean(o) ≈ vec(mean(x, 1))
    @test var(o) ≈ vec(var(x, 1))
    @test cov(o) ≈ cov(x) atol=.001
    @test cor(o) ≈ cor(x) atol=.001
    @test std(o) ≈ vec(std(x, 1))

    x2 = randn(101, 5)
    o2 = CovMatrix(5)
    s2 = Series(o2)
    fit!(s2, x2, 10)
    merge!(s, s2)
    @test nobs(s) == 201
    @test cov(o) ≈ cov(vcat(x, x2))
end
@testset "KMeans" begin
    x = randn(100, 3)
    o = KMeans(3, 5)
    s = Series(x, o)
    fit!(s, x, 5)
end
@testset "Bootstrap" begin
    b = Bootstrap(Series(Mean()), 100, [0, 2])
    fit!(b, randn(1000))
    value(b)        # `fun` mapped to replicates
    mean(value(b))  # mean
    @test replicates(b) == b.replicates
    confint(b)
end


end
