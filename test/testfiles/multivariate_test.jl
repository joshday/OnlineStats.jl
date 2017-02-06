module MultivariateTest
using OnlineStats, Base.Test
using Distributions

@testset "Multivariate" begin

    @testset "KMeans" begin
        x = vcat(randn(1000, 5), 10 + randn(1000, 5))
        o = KMeans(x, 2)
        o = KMeans(x, 2, 10)
        
        @test nobs(o)       == 2000
        @test size(o.value) == (5, 2)
    end

    @testset "MvNormal" begin
        z = MvNormal([1, 2], 3)
        o = FitMvNormal(size(z)[1])
        N = 100000
        for _ in 1:N
                fit!(o, rand(z))
        end
        z2 = value(o)

        # tolerances are generous, but there is a small probability that this
        # stochastic test will fail occasionally. in that case, rerun.
        @test nobs(o) == N
        @test isapprox(mean(z2), mean(z), atol=0.1)
        @test isapprox(var(z2), var(z), atol=0.1)
    end

end

end#module
