module MultivariateTest
using OnlineStats, Base.Test

@testset "Multivariate" begin
@testset "KMeans" begin
    x = vcat(randn(1000, 5), 10 + randn(1000, 5))
    o = KMeans(x, 2)
    o = KMeans(x, 2, 10)

    @test nobs(o)       == 2000
    @test size(o.value) == (5, 2)
end
end
end#module
