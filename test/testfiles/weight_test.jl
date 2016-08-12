module WeightTest

using TestSetup, OnlineStats, Base.Test
O = OnlineStats

@testset "Weighting" begin
    @testset "EqualWeight" begin
        w = EqualWeight()
        O.updatecounter!(w)
        @test O.weight(w) == 1.0
        O.updatecounter!(w, 5)
        @test O.weight(w, 5) == 5 / 6
    end
    @testset "ExponentialWeight" begin
        w = ExponentialWeight(.5)
        O.updatecounter!(w)
        @test O.weight(w) == 0.5
        O.updatecounter!(w, 5)
        @test O.weight(w) == 0.5
        @test ExponentialWeight(5).λ == ExponentialWeight(1/3).λ
    end
    @testset "BoundedEqualWeight" begin
        w = BoundedEqualWeight(.1)
        O.updatecounter!(w)
        @test O.weight(w, 1) == 1.0
        O.updatecounter!(w, 100)
        @test O.weight(w) == 0.1
        @test BoundedEqualWeight(5).λ == BoundedEqualWeight(1/3).λ
    end
    @testset "LearningRate" begin
        w = LearningRate(.6)
        O.updatecounter!(w)
        @test O.weight(w) == 1.0
        O.updatecounter!(w, 5)
        @test O.weight(w, 5) == 2 ^ -.6
        @test O.nups(w) == 2
    end
    @testset "LearningRate2" begin
        w = LearningRate2(0.5)
        O.updatecounter!(w)
        @test O.weight(w) == 1.0
        O.updatecounter!(w, 5)
        @test O.weight(w, 5) == 1 / (1 + .5)
    end
end  # facts
end  # module
