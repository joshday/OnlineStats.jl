module OnlineStatsTest
using OnlineStats, Base.Test, Distributions

info("Messy output for test coverage")
@testset "show" begin
    show(OnlineStats.ScalarIn)
    show(OnlineStats.ScalarOut)
    println(Series(Mean()))
    println(OrderStats(5))
    println(Moments())
    println(QuantileMM())
    println(NormalMix(2))
    @testset "maprows" begin
        s = Series(Mean(), Variance())
        println()
        maprows(10, randn(100)) do yi
            fit!(s, yi)
            print("$(nobs(s)), ")
        end
        println()
        @test nobs(s) == 100
    end
end



println()
println()
info("TESTS BEGIN HERE")


@testset "Weights" begin
    w1 = EqualWeight()
    w2 = ExponentialWeight()
    w3 = BoundedEqualWeight()
    w4 = LearningRate()

    for w in [w1, w3, w4]
        @test OnlineStats.weight(w, 1, 1, 1) == 1
    end
    for i in 1:10
        @test OnlineStats.weight(w1, i, 1, i) == 1 / i
        @test OnlineStats.weight(w2, i, 1, i) == w2.λ
        @test OnlineStats.weight(w3, i, 1, i) == 1 / i
        @test OnlineStats.weight(w4, i, 1, i) ≈ i ^ -w4.r
    end
    @test OnlineStats.weight(w3, 1_000_000, 1, 1_000_000) == w3.λ
end

@testset "Constructors" begin
    Mean()
    Variance()
    Extrema()
    OrderStats(100)
    Moments()
    QuantileSGD()
    QuantileMM()
    Diff()
    Sum()
    NormalMix(5)
    MV(5, Mean())
    MV(5, Sum())
    CovMatrix(4)
    Series(Mean(), Variance())
    Series(randn(100), Mean(), Variance())
    Series(CovMatrix(4), MV(4, Mean()))
    Series(:myid, EqualWeight(), Mean())
    Series(EqualWeight(), :myid, Variance())
    @test_throws ArgumentError Series(CovMatrix(4), Mean())
end
@testset "Series{ScalarIn}" begin
    for o in [Mean(), Variance(), Extrema(), OrderStats(10), Moments(), QuantileSGD(),
              QuantileMM(), Diff(), Sum()]
        s = Series(randn(100), o)
        @test value(o) == value(s, 1)
        @test value(s) == tuple(value(o))
        @test typeof(stats(s)) == Tuple{typeof(o)}
    end
end
@testset "Series{VectorIn}" begin
    for o in [MV(5, Mean()), MV(5, Variance()), CovMatrix(5)]
        s = Series(randn(100, 5), o)
        @test value(o) == value(s, 1)
        @test value(s) == tuple(value(o))
        @test typeof(stats(s)) == Tuple{typeof(o)}
    end
end
@testset "Series merge" begin
    y1 = randn(100)
    y2 = randn(100)
    y = vcat(y1, y2)
    o = Series(y1, Mean(), Variance())
    o2 = Series(y2, Mean(), Variance())
    merge!(o, o2)
    @test value(o, 1) ≈ mean(y)
    @test value(o, 2) ≈ var(y)
    merge(Mean(), Mean(), .1)
end

@testset "Summary" begin
    y1 = randn(500)
    y2 = randn(501)
    y = vcat(y1, y2)
    @testset "Mean" begin
        o1 = Series(y1, Mean())
        @test value(o1, 1) ≈ mean(y1)
        @test nobs(o1) == 500

        o2 = Series(y2, Mean())
        @test value(o2, 1) ≈ mean(y2)

        o3 = merge(o1, o2)
        @test value(o3, 1) ≈ mean(y)
        @test mean(stats(o3, 1)) ≈ mean(y)
    end
    @testset "Variance" begin
        o1 = Series(y1, Variance())
        @test value(o1, 1) ≈ var(y1)
    end
    @testset "Extrema" begin
        o = Series(y1, Extrema())
        @test value(o, 1) == extrema(y1)
    end
    @testset "QuantileMM/QuantileSGD" begin
        o = Series(y1, QuantileMM(.1, .2, .3), QuantileSGD(.4, .5))
        o = Series(y1, QuantileMM(), QuantileSGD(); weight = LearningRate())
        fit!(o, y2, 5)

        o = QuantileMM()
        OnlineStats.fitbatch!(o, randn(10), .1)
        o = QuantileSGD()
        OnlineStats.fitbatch!(o, randn(10), .1)
    end
    @testset "Moments" begin
        x = randn(10_000)
        s = Series(x, Moments())
        o = stats(s, 1)
        @test mean(o)       ≈ mean(x)       atol = 1e-4
        @test var(o)        ≈ var(x)        atol = 1e-4
        @test std(o)        ≈ std(x)        atol = 1e-4
        @test skewness(o)   ≈ skewness(x)   atol = 1e-3
        @test kurtosis(o)   ≈ kurtosis(x)   atol = 1e-3

        x2 = randn(1000)
        s2 = Series(x2, Moments())
        merge!(s, s2)
        @test nobs(s) == 11_000

        @test value(s, 1) ≈ value(Series(vcat(x, x2), Moments()), 1)
    end
    @testset "Diff" begin
        Diff()
        Diff(Float64)
        Diff(Float32)
        Diff(Int64)
        Diff(Int32)
        y = randn(100)
        s = Series(y, Diff())
        o = stats(s, 1)
        @test typeof(o) == Diff{Float64}
        @test last(o) == y[end]
        @test diff(o) == y[end] - y[end-1]

        y = rand(Int, 100)
        s = Series(y, Diff(Int))
        o = stats(s, 1)
        @test typeof(o) == Diff{Int}
        @test last(o) == y[end]
        @test diff(o) == y[end] - y[end-1]
    end
    @testset "Sum" begin
        Sum()
        Sum(Float64)
        Sum(Float32)
        Sum(Int64)
        Sum(Int32)

        y = randn(100)
        s = Series(y, Sum())
        o = stats(s, 1)
        @test typeof(o) == Sum{Float64}
        @test sum(o) ≈ sum(y)
        @test value(o) == sum(o)

        y = rand(Int, 100)
        s = Series(y, Sum(Int))
        o = stats(s, 1)
        @test typeof(o) == Sum{Int}
        @test sum(o) ≈ sum(y)
    end
end # summary

@testset "Distributions" begin
    @testset "FitBeta" begin
        d = Beta(3, 5)
        y = rand(d, 1000)
        o = FitBeta()
        s = Series(y, o)
        @test mean(o) ≈ mean(y)
        @test var(o) ≈ var(y)
        @test std(o) ≈ std(y)
        @test params(o) == params(value(o))
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
    end
    @testset "FitCauchy" begin
        d = Cauchy()
        y = rand(d, 10_000)
        o = FitCauchy()
        s = Series(y, o; weight = LearningRate())
        myfit = fit(Cauchy, y)
        θ = params(value(o))
        @test params(value(o))[1] ≈ params(myfit)[1] atol = .1
        @test params(value(o))[2] ≈ params(myfit)[2] atol = .1
    end
    @testset "FitGamma" begin
        d = Gamma(5, 1)
        y = rand(d, 10_000)
        o = FitGamma()
        s = Series(y, o)
        myfit = fit(Gamma, y)
        @test mean(o)   ≈ mean(myfit)   atol=.01
        @test var(o)    ≈ var(myfit)    atol=.1
        @test std(o)    ≈ std(myfit)    atol=.1
    end
    @testset "FitLogNormal" begin
        d = LogNormal()
        y = rand(d, 1000)
        o = FitLogNormal()
        s = Series(y, o)
        myfit = fit(LogNormal, y)
        @test mean(o) ≈ mean(myfit)
        @test var(o) ≈ var(myfit)
        @test std(o) ≈ std(myfit)
    end
    @testset "FitMultinomial" begin
    end
    @testset "FitMvNormal" begin
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
    s = Series(rand(1:100, 10_000), o)
    @test 90 < value(o) < 110
end
@testset "CovMatrix" begin
    x = randn(100, 5)
    o = CovMatrix(5)
    s = Series(x, o)
    fit!(s, x, 10)
    OnlineStats.fitbatch!(o, x, .1)

    o = CovMatrix(5)
    s = Series(o)
    fit!(s, x, 10)
    @test mean(o) ≈ vec(mean(x, 1))
    @test var(o) ≈ vec(var(x, 1))
    @test cov(o) ≈ cov(x) atol=.001
    @test cor(o) ≈ cor(x) atol=.001
end

end
