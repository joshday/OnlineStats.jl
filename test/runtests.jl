module OnlineStatsTest
using OnlineStats, Base.Test


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

include("testfiles/summary_test.jl")

end
