module DistributionsTest
using OnlineStats, Distributions, Base.Test
srand(02082016)

@testset "Distributions" begin
@testset "fitdistribution" begin
    y = rand(Beta(), 100)
    fitdistribution(Beta, y)

    y = rand(Categorical([.2, .2, .2, .4]), 100)
    fitdistribution(Categorical, y)

    y = rand(Cauchy(), 100)
    fitdistribution(Cauchy, y)

    y = rand(Gamma(2, 6), 100)
    fitdistribution(Gamma, y)

    y = randn(100)
    fitdistribution(Normal, y)

    x = rand(10)
    y = rand(Multinomial(5, x/sum(x)), 100)'
    fitdistribution(Multinomial, y)

    y = rand(MvNormal(zeros(4), diagm(ones(4))), 100)'
    fitdistribution(MvNormal, y)
end
@testset "Beta" begin
    y = rand(Beta(), 100)
    o = FitBeta(y)
    d = fit(Beta, y)
    @test mean(o)       ≈ mean(d)
    @test var(o)        ≈ var(d)
    @test params(o)[1]  ≈ params(d)[1]
    @test params(o)[2]  ≈ params(d)[2]
    @test nobs(o)       ≈ 100
end
@testset "Categorical" begin
    y = rand(Categorical([.2, .2, .2, .4]), 1000)
    o = FitCategorical(y)
    @test typeof(o) == FitCategorical{Int64}
    @test ncategories(o) == 4

    y = rand(Bool, 1000)
    o = FitCategorical(y)
    @test ncategories(o) == 2

    y = rand([:a, :b, :c, :d, :e, :f, :g], 1000)
    o = FitCategorical(y)
    @test ncategories(o) == 7
end
@testset "Cauchy" begin
    y = rand(Cauchy(), 10000)
    o = FitCauchy(y, LearningRate())
    fit!(o, y)
    @test params(o)[1] ≈ 0.0 atol=0.1
    @test params(o)[2] ≈ 1.0 atol=0.1
    @test nobs(o) == 2 * 10000
end
@testset "Gamma" begin
    y = rand(Gamma(2, 6), 100)
    o = FitGamma(y)
    @test mean(o) ≈ mean(y)
end
@testset "LogNormal" begin
    y = rand(LogNormal(), 100)
    o = FitLogNormal(y)
    @test mean(o) ≈ mean(y) atol=.1
end
@testset "Normal" begin
    y = randn(100)
    o = FitNormal(y)
    @test mean(o) ≈ mean(y)
    @test std(o) ≈ std(y)
    @test var(o) ≈ var(y)
end
@testset "Multinomial" begin
    x = rand(10)
    y = rand(Multinomial(5, x/sum(x)), 100)'
    o = FitMultinomial(y)
    @test mean(o) ≈ vec(mean(y, 1))
    @test nobs(o) == 100
end
@testset "MvNormal" begin
    ## constructor using a vector of values
    y = rand(MvNormal(zeros(4), diagm(ones(4))), 100)'
    o = FitMvNormal(y)
    @test mean(o) ≈ vec(mean(y, 1))
    @test var(o) ≈ vec(var(y, 1))
    @test std(o) ≈ vec(std(y, 1))
    @test cov(o) ≈ cov(y)
    @test nobs(o) == 100

    ## empty costructor
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
@testset "NormalMix" begin
    d = MixtureModel(Normal, [(0,1), (2,3), (4,5)])
    y = rand(d, 50_000)
    o = NormalMix(y, 3)

    fit!(o, y)
    fit!(o, y, 10)
    @test mean(o) ≈ mean(y) atol=.5
    @test var(o)  ≈ var(y)  atol=.5
    @test std(o)  ≈ std(y)  atol=.5
    @test length(componentwise_pdf(o, 0.5)) == 3
    @test ncomponents(o) == 3
    @test typeof(component(o, 1)) == Normal{Float64}
    @test length(probs(o)) == 3
    @test pdf(o, randn()) > 0
    @test 0 < cdf(o, randn()) < 1
    @test value(o) == o.value
    @test quantile(o, [.25, .5, .75]) ≈ quantile(y, [.25, .5, .75]) atol=.5
    quantile(o, collect(.01:.01:.99))

    fit!(o, y, 1)
    fit!(o, y, 2)
    fit!(o, y, 5)
    NormalMix(3, y)
end
end

end#module
