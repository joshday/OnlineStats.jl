module StatLearnTest
using OnlineStats, Distributions, Base.Test

function linearmodeldata(n, p, corr = 0)
    # linear model data with correlated predictors
    V = zeros(p, p)
    for j in 1:p, i in 1:p
        V[i, j] = corr^abs(i - j)
    end
    x = rand(MvNormal(ones(p), V), n)'
    β = vcat(1.:5, zeros(p-5))
    y = x*β + randn(n)
    (β, x, y)
end

@testset "StatLearn" begin
    n, p = 500, 5
    x = randn(n, p)
    β = collect(linspace(-1, 1, p))
    β_with_intercept = vcat(0.0, β)
    xβ = x*β

    generate(::LinearRegression, xβ) = xβ + randn(size(xβ, 1))
    generate(::L1Regression, xβ) = xβ + randn(size(xβ, 1))
    generate(::LogisticRegression, xβ) = [rand(Bernoulli(1 / (1 + exp(-η)))) for η in xβ]
    generate(::PoissonRegression, xβ) = [rand(Poisson(exp(η))) for η in xβ]
    generate(::QuantileRegression, xβ) = xβ + randn(size(xβ, 1))
    generate(::SVMLike, xβ) = [rand(Bernoulli(1 / (1 + exp(-η)))) for η in xβ]
    generate(::HuberRegression, xβ) = xβ + randn(size(xβ, 1))

    @testset "methods" begin
        y = x*β + randn(n)
        o = StatLearn(x, y)
        @test predict(o, x) ≈ x * o.β + o.β0
        @test coef(o) == vcat(o.β0, o.β)
    end
    @testset "loss" begin
        y = generate(LinearRegression(), xβ)
        o = StatLearn(x, y, LinearRegression())
        @test loss(o, x, y) ≈ .5 * mean(abs2(y - predict(o, x)))

        y = generate(L1Regression(), xβ)
        o = StatLearn(x, y, L1Regression())
        @test loss(o, x, y) ≈ mean(abs(y - predict(o, x)))

        y = generate(LogisticRegression(), xβ)
        o = StatLearn(x, y, LogisticRegression())
        η = o.β0 + x * o.β
        l = mean([-y[i] * η[i] + log(1.0 + exp(η[i])) for i in 1:length(η)])
        @test loss(o, x, y) ≈ l

        y = generate(PoissonRegression(), xβ)
        o = StatLearn(x, y, PoissonRegression())
        η = o.β0 + x * o.β
        # TODO
        # @test loss(o, x, y) ≈ mean(-y .* η + exp(η))

        y = generate(QuantileRegression(.7), xβ)
        o = StatLearn(x, y, QuantileRegression(.7))
        r = y - o.β0 - x * o.β
        @test loss(o, x, y) ≈ mean([r[i] * (o.model.τ - (r[i]<0)) for i in 1:n])

        y = generate(SVMLike(), xβ)
        o = StatLearn(x, y, SVMLike())
        η = o.β0 + x * o.β
        @test loss(o, x, y) ≈ mean([max(0.0, 1.0 - y[i] * η[i]) for i in 1:n])

        y = generate(HuberRegression(4.), xβ)
        o = StatLearn(x, y, HuberRegression(4.))
        δ = o.model.δ
        r = y - o.β0 - x * o.β
        v = [abs(r[i]) < δ? 0.5 * r[i]^2 : δ * (abs(r[i]) - 0.5 * δ) for i in 1:n]
        @test loss(o, x, y) ≈ mean(v)
    end
end


end #module
