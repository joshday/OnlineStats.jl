module OnlineStatsTest
using OnlineStats, Base.Test

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
    end
end
@testset "Series{VectorIn}" begin
    for o in [MV(5, Mean()), MV(5, Variance()), CovMatrix(5)]
        s = Series(randn(100, 5), o)
        @test value(o) == value(s, 1)
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
        o = Series(y1, QuantileMM(), QuantileSGD(); weight = LearningRate())
    end
    @testset "Moments" begin
        x = randn(10_000)
        s = Series(x, Moments())
        o = stats(s, 1)
        @test mean(o)       ≈ mean(x)       atol = 1e-4
        @test var(o)        ≈ var(x)        atol = 1e-4
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

end
