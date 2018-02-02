@testset "Mosaic" begin
    o = Mosaic(Bool, Bool)
    series(rand(Bool, 100, 2), o)
    @test nobs(o) == 100
end