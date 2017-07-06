module OnlineStatsTest
using OnlineStats, Base.Test, Distributions, LearnBase
using LossFunctions, PenaltyFunctions

#-----------------------------------------------------------# coverage for show()
info("Messy output for test coverage")
@testset "show" begin
    println(Series(Mean()))
    println(Series(Mean(), Variance()))
    # println(Bootstrap(Series(Mean()), 100, Poisson()))
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
    println(LinReg(5))
    # println(StatLearn(5))
    o = Mean()
    Series(LearningRate(), o)
    for stat in o
        println(stat)
    end
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
    w6 = @inferred McclainWeight()
    w7 = @inferred HarmonicWeight(5.)

    for w in [w1, w3, w4, w5, w6, w7]
        @test OnlineStats.weight!(w, 1) == 1
    end
    for i in 1:10
        @test OnlineStats.weight(w1) == 1 / i
        @test OnlineStats.weight(w2) == w2.λ
        @test OnlineStats.weight(w3) == 1 / i
        @test OnlineStats.weight(w4) ≈ i ^ -w4.r
        @test OnlineStats.weight(w5) ≈ 1 / (1 + w5.c * (i-1))
        @test OnlineStats.weight(w7) ≈ 5. / (5. + i - 1)
        map(OnlineStats.updatecounter!, [w1, w2, w3, w4, w5, w7])
    end

    @inferred ExponentialWeight(100)
    @inferred BoundedEqualWeight(100)
    @inferred McclainWeight(.2)
    @test_throws ArgumentError McclainWeight(-1.)
    @test_throws ArgumentError McclainWeight(1.1)

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

    y1, y2 = randn(5, 2), randn(10, 2)
    o1, o2 = MV(2, Mean()), MV(2, Mean())
    s1, s2 = Series(y1, o1), Series(y2, o2)
    merge!(s1, s2)
    @test nobs(s1) == 15
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
    @testset "StochasticLoss" begin
        o1 = StochasticLoss(QuantileLoss(.7))  # approx. .7 quantile
        o2 = StochasticLoss(L2DistLoss())      # approx. mean
        o3 = StochasticLoss(L1DistLoss())      # approx. median
        s = Series(randn(1_000), o1, o2, o3)
    end
    @testset "QuantileMM/QuantileSGD/QuantileISGD" begin
        s = @inferred Series(y1,
            QuantileMM(.2, .3), QuantileSGD([.4, .5]), QuantileISGD([.6, .7]))
        @test typeof(s.weight) == LearningRate
        s = @inferred Series(y1, QuantileMM(.2, .3), QuantileSGD([.4, .5]))
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

        o1 = QuantileSGD(.4, .5)
        o2 = QuantileSGD(.4, .5)
        merge!(o1, o2, .5)

        o = Diff(Int64)
        @test typeof(o) == Diff{Int64}
        fit!(o, 5, .1)

        o = Sum(Int64)
        @test sum(o) == 0
        @test typeof(o) == Sum{Int64}
        fit!(o, 5, .1)

        y1 = randn(100)
        y2 = randn(100)
        s1 = Series(y1, Extrema())
        s2 = Series(y2, Extrema())
        merge!(s1, s2)
        @test value(s1) == extrema(vcat(y1, y2))
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
            for i in 1:length(Distributions.params(o))
                @test Distributions.params(o)[i] ≈ Distributions.params(myfit)[i] atol = tol
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

        vals = ["small", "big"]
        Series(rand(vals, 100), FitCategorical(String))
    end
    @testset "FitMultinomial" begin
        y = rand(Multinomial(10, ones(5) / 5), 1000)
        myfit = fit(Multinomial, y)
        o = FitMultinomial(5)
        @test Distributions.params(value(o)) == (1, ones(5) / 5)
        s = Series(o)
        fit!(s, y')
        @test probs(o) ≈ probs(myfit)
    end
    @testset "FitMvNormal" begin
        y = rand(MvNormal(zeros(3), eye(3)), 1000)
        myfit = fit(MvNormal, y)
        o = FitMvNormal(3)
        @test length(o) == 3
        @test Distributions.params(value(o))[1] == zeros(3)
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
    @test cov(o) ≈ cov(x)
    @test cor(o) ≈ cor(x)
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
    confint(b, .95, :normal)
    @test_throws Exception confint(b, .95, :fake_method)

    b = Bootstrap(Series(MV(3, Mean())), 100, Poisson())
    fit!(b, randn(100, 3))
end
@testset "Column obs." begin
    x = randn(5, 1000)

    o = CovMatrix(5)
    s = Series(o)
    fit!(s, x, ObsDim.Last())
    @test value(s) ≈ cov(x')
    fit!(s, x, .1, ObsDim.Last())
    fit!(s, x, rand(1000), ObsDim.Last())

    o1 = CovMatrix(5)
    o2 = MV(5, Mean())
    s = Series(o1, o2)
    fit!(s, x, ObsDim.Last())
    @test value(s)[2] ≈ mean(x, 2)
    fit!(s, x, .1, ObsDim.Last())
    fit!(s, x, rand(1000), ObsDim.Last())
end
@testset "StatLearn" begin
    n, p = 1000, 10
    x = randn(n, p)
    y = x * linspace(-1, 1, p) + .5 * randn(n)

    for u in [SPGD(), MAXSPGD(), ADAGRAD(), ADAM(), ADAMAX(), MMXTX()]
        o = @inferred StatLearn(p, scaled(L2DistLoss(), .5), L2Penalty(), fill(.1, p), u)
        s = @inferred Series(o)
        fit!(s, x, y)
        fit!(s, x, y, .1)
        fit!(s, x, y, rand(length(y)))
        fit!(s, x, y, 10)
        @test nobs(s) == 4 * n
        @test coef(o) == o.β
        @test predict(o, x) == x * o.β
        @test predict(o, x[1,:]) == x[1,:]'o.β
        @test loss(o, x, y) == value(o.loss, y, predict(o, x), AvgMode.Mean())

        o = StatLearn(p, LogitMarginLoss())
        o.β[:] = ones(p)
        @test classify(o, x) == sign.(vec(sum(x, 2)))

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
@testset "LinReg" begin
    n, p = 1000, 10
    x = randn(n, p)
    y = x * linspace(-1, 1, p) + randn(n)

    o = LinReg(p)
    s = Series(o)
    fit!(s, x, y)
    fit!(s, x, y, 9)
    @test nobs(s) == 2n
    @test nobs(o) == 2n
    @test coef(o) == value(o)
    @test coef(o) ≈ x\y

    # merge
    n2 = 500
    x2 = randn(n2, p)
    y2 = x2 * linspace(-1, 1, p) + randn(n2)
    o1 = LinReg(p)
    o2 = LinReg(p)
    s1 = Series(o1)
    s2 = Series(o2)
    fit!(s1, x, y)
    fit!(s2, x2, y2)
    merge!(s1, s2)
    @test coef(o1) ≈ vcat(x, x2) \ vcat(y, y2)

    mse(o)
    coeftable(o)
    confint(o)
    vcov(o)
    stderr(o)

    o = LinReg(p, .1)
    s = Series(o)
    fit!(s, x, y)
    value(o)
    @test predict(o, x) == x * o.β
end
@testset "ReservoirSample" begin
    o = ReservoirSample(100, Int64)
    s = Series(o)
    fit!(s, 1:1000)
    for j in 1:100
        @test o.value[j] in 1:1000
    end
end


end
