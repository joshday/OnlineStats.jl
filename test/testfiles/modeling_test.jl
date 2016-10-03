module ModelingTest
using OnlineStats, GLM, Base.Test

@testset "Modeling" begin
@testset "LinReg" begin
    n, p = 10000, 10
    x = randn(n, p)
    β = collect(1.:p)
    y = x * β + randn(n)
    o = LinReg(x, y, intercept = false)
    @test coef(o)[2] ≈ x \ y
    o2 = LinReg(10, intercept = false)
    fit!(o2, x[1:500, :], y[1:500], 500)
    fit!(o2, x[501:1000, :], y[501:1000], 1)
    @test_approx_eq_eps coef(o)[2] coef(o2)[2] .5

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

    @test coef(LinReg(10, intercept = false))[2] == zeros(10)
    @test vcat(coef(LinReg(10))...) == zeros(11)

    o = LinReg(10)
    @test coef(o) == value(o)
    predict(o, randn(100, 10)) == zeros(100)
end
@testset "QuantRegMM" begin
    n, p = 10000, 10
    x = randn(n, p)
    β = collect(1.:p)
    y = x * β + randn(n)

    o = QuantRegMM(x, y)
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
