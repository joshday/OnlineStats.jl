module FitMethodsTest
using OnlineStats, BaseTestNext

@testset "fit! methods" begin
    @testset "Single Observation" begin
        o = Mean()
        fit!(o, randn())
        fit!(o, randn(), rand())
        @test nobs(o) == 2

        o = Means(2)
        fit!(o, randn(2))
        fit!(o, randn(2), rand())
        @test nobs(o) == 2

        o = LinReg(2)
        fit!(o, randn(2), randn())
        fit!(o, randn(2), randn(), rand())
        @test nobs(o) == 2
    end
    @testset "Multiple Observations" begin
        o = Mean()
        fit!(o, randn(100))
        fit!(o, randn(100), rand(100))
        fit!(o, randn(100), .1)
        @test nobs(o) == 300

        o = Means(2)
        fit!(o, randn(100, 2))
        fit!(o, randn(100, 2), rand(100))
        fit!(o, randn(100, 2), .1)
        @test nobs(o) == 300

        o = LinReg(2)
        fit!(o, randn(100, 2), randn(100))
        fit!(o, randn(100, 2), randn(100), rand(100))
        fit!(o, randn(100, 2), randn(100), .1)
        @test nobs(o) == 300
    end
    @testset "maprows" begin
        o = Mean()
        o2 = Mean()
        y = randn(100)
        fit!(o, y)
        maprows(10, y) do yi
            fit!(o2, yi)
        end
        @test mean(o) == mean(o2)
    end
end

end  # module
