println()
println()
info("Testing Series")
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

    @testset "column observations" begin 
        s = Series(CovMatrix(5))
        fit!(s, x', Cols())
        @test s == Series(x, CovMatrix(5))
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
    # multiple observations
    s = Series(LinReg(5))
    fit!(s, (x, y))
    @test value(s)[1] ≈ x\y
    # multiple observations, by column
    s = Series(LinReg(5))
    fit!(s, (x', y), Cols())
    @test value(s)[1] ≈ x\y
end
@testset "merging" begin 
    @test merge(Series(Mean()), Series(Mean())) == Series(Mean())
    s1 = merge(Series(y, Mean()), Series(y2, Mean()))
    s2 = Series(vcat(y,y2), Mean())
    @test value(s1)[1] ≈ value(s2)[1]
    @test_throws Exception merge(Series(y, Mean()), Series(y, Mean()), 100.0)
    merge(s1, s2, :singleton)
    @test_throws Exception merge(s1, s2, :fakemethod)

    s1 = Series(y, Mean())
    s2 = Series(y2, Mean())
    merge!(s1, s2)
    @test value(stats(s1)[1]) ≈ mean(vcat(y, y2))

    s1 = Series([1], Mean())
    s2 = Series([2], Mean())
    merge!(s1, s2, .9)
    @test value(s1)[1] ≈ .1*1 + .9*2

    s1 = Series(y, Mean())
    s2 = Series(y2, Mean())
    merge!(s1, s2, :singleton)
    @test value(s1)[1] ≈ mean(vcat(y, mean(y2)))
end
@testset "Non-standard things" begin 
    s = Series(Mean())
    s([1,2,3])
    s(s, [1,2,3])
    @test value(s)[1] ≈ 2

    o = Mean()
    fit!(o, y)
    @test value(o) ≈ mean(y)
end
end #Series

#-----------------------------------------------------------------------# AugmentedSeries
@testset "AugmentedSeries" begin 
    data = randn(100)
    @test value(series(data, Mean(), transform=abs))[1] ≈ mean(abs, data)
    @testset "Sanity Check" begin
        # N = 0
        s = series(Mean(), Variance(); transform = abs)
        @test s isa AugmentedSeries
        data = randn(100)
        fit!(s, data)
        @test value(s)[1] ≈ mean(abs.(data))
        @test value(s)[2] ≈ var(abs.(data))

        # N = 1
        s = series(2Mean(); transform = x -> abs.(x))
        @test s isa AugmentedSeries
        data = randn(100, 2)
        fit!(s, data)
        @test value(s)[1] ≈ vec(mean(abs.(data), 1))

        # N = (1, 0)
        s = series(LinReg(2); transform = xy -> (xy[1], abs(xy[2])))
        @test s isa AugmentedSeries
        data = (randn(100, 2), randn(100))
        fit!(s, data)
        @test coef(stats(s)[1]) ≈ data[1] \ abs.(data[2])
    end
    @testset "merging" begin 
        # test 1
        o, o2 = merge_vs_fit(Mean(), y, y2, transform = abs)
        @test value(o) ≈ mean(abs, vcat(y, y2))
        @test value(o2) ≈ mean(abs, vcat(y, y2))

        # test 2
        s1, s2 = series(y, Mean(); transform = abs), series(y2, Mean(); transform = abs)
        merge!(s1, s2, .5)
        fit!(s2, y)
        @test value(s1)[1] ≈ value(s2)[1]
        @test_throws Exception merge!(s1, s2, :fake_method)

        # test 3
        s1, s2 = series(y, Mean(); transform = abs), series(y2, Mean(); transform = abs)
        merge!(s1, s2, :singleton)
        @test value(s1)[1] ≈ mean(abs, vcat(y, mean(abs, y2)))

    end
end