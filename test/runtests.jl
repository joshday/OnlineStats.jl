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
    @test_throws ArgumentError Series(CovMatrix(4), Mean())
end
@testset "fit: NumberIn" begin
    for o in [Mean(), Variance(), Extrema(), OrderStats(10), Moments(), QuantileSGD(),
              QuantileMM(), Diff(), Sum()]
        s = fit(o, randn(100))
        @test value(o, 100) == value(s, 1)
    end
end
@testset "fit: VectorIn" begin
    for o in [MV(5, Mean()), MV(5, Variance()), CovMatrix(5)]
        s = fit(o, randn(100, 5))
        @test value(o) == value(s, 1)
    end
end

end
