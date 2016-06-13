module ModelingTest
using OnlineStats, GLM, BaseTestNext
import OnlineStats: add_deriv, _j

@testset "Modeling" begin
@testset "sweep! operator" begin
    x = randn(100, 10)
    A = x'x
    B = x'x
    sweep!(A, 2:4)
    sweep!(A, 2:4, true)
    @test A ≈ B
    v = zeros(10)
    sweep!(A, 1:5, v)
    sweep!(A, 1:5, v, true)
    @test A ≈ B
end
@testset "LinReg" begin
    n, p = 10000, 10
    x = randn(n, p)
    β = collect(1.:p)
    y = x * β + randn(n)
    o = LinReg(x, y, intercept = false)
    @test coef(o) ≈ x \ y
    o2 = LinReg(10, intercept = false)
    fit!(o2, x[1:500, :], y[1:500], 500)
    fit!(o2, x[501:1000, :], y[501:1000], 1)
    @test_approx_eq_eps coef(o) coef(o2) .5

    # vs. GLM
    l = lm(x, y)
    @test predict(l, x) ≈ predict(o, x)
    xi = randn(p)
    @test predict(l, xi') ≈ collect(predict(o, xi))
    @test loss(o, x, y) ≈ 0.5 * mean(abs2(y - predict(o, x)))
    ltab = coeftable(l)
    otab = coeftable(o)

    @test_approx_eq_eps vcov(o)[1:5]    vcov(l)[1:5]    .1
    @test_approx_eq_eps stderr(o)[1:5]  stderr(l)[1:5]  .1
    @test_approx_eq_eps confint(o)[1:5] confint(l)[1:5] .1

    @test coef(LinReg(10, intercept = false)) == zeros(10)
    @test coef(LinReg(10)) == zeros(11)

    o = LinReg(10)
    @test coef(o) == value(o)
    predict(o, randn(100, 10)) == zeros(100)
end
@testset "Penalties" begin
    NoPenalty()
    LassoPenalty(.1)
    RidgePenalty(.1)
    p = ElasticNetPenalty(.1, .5)
    p2 = SCADPenalty(.1)

    β = randn(5)
    @test _j(NoPenalty(), β)        == 0.0
    @test _j(LassoPenalty(.1), β)   == .1 * sumabs(β)
    @test _j(RidgePenalty(.1), β)   == 0.5 * .1 * sumabs2(β)
    @test _j(p, β)                  == .1 * (p.α * sumabs(β) + (1 - p.α) * 0.5 * sumabs2(β))
    @test _j(p2, .01)               == .1 *.01

    p3 = SCADPenalty(.2)
    g = randn()
    βj = randn()
    λ = rand()
    @test add_deriv(NoPenalty(), g, βj)     == g
    @test add_deriv(RidgePenalty(λ), g, βj) == g + λ * βj
    @test add_deriv(LassoPenalty(λ), g, βj) == g + λ * sign(βj)
    @test add_deriv(p, g, βj)               == g + p.λ * (p.α * sign(βj) + (1 - p.α) * βj)
    @test add_deriv(p3, g, .1) == g + .2
    @test add_deriv(p3, g, .2) == g + max(3.7 * .2 - .2, 0.0) / (3.7 - 1.0)
    @test add_deriv(p3, g, 20) == g

    β = randn(5)
    β2 = copy(β)
    OnlineStats.prox!(LassoPenalty(.1), β, .5)
    @test β[1] == OnlineStats.prox(LassoPenalty(.1), β2[1], .5)
end
@testset "QuantReg" begin
    n, p = 10000, 10
    x = randn(n, p)
    β = collect(1.:p)
    y = x * β + randn(n)

    o = QuantReg(x, y)
    fit!(o, x, y, 10)

    @test coef(o) == value(o)
    @test value(o) == o.β
end
@testset "BiasVector / BiasMatrix" begin
    x = randn(100, 10)
    y = randn(100)
    yb = BiasVector(y)
    xb = BiasMatrix(x)

    @test length(yb)    == 101
    @test size(yb)      == (101,)
    @test length(xb)    == 100 * 10 + 100
    @test size(xb)      == (100, 11)
    @test yb[101]       == 1
    @test xb[1, 11]     == 1
    xb[1, 1] = 2.0
    yb[1] = 2.0
    @test xb[1, 1]      == 2.0
    @test yb[1]         == 2.0
end
@testset "TwoWayInteractionVector/Matrix" begin
    x = rand(5)
    v = TwoWayInteractionVector(x)
    @test v[5]  == x[5]
    @test v[6]  == x[1] * x[2]
    @test v[7]  == x[1] * x[3]
    @test v[8]  == x[1] * x[4]
    @test v[9]  == x[1] * x[5]
    @test v[10] == x[2] * x[3]

    x = rand(10, 5)
    m = TwoWayInteractionMatrix(x)
    @test m[1, 1]   == x[1, 1]
    @test m[1, 5]   == x[1, 5]
    @test m[1, 6]   == x[1, 1] * x[1, 2]
    @test m[1, 10]  == x[1, 2] * x[1, 3]
end
end

end#module
