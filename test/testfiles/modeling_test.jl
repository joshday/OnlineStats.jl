module ModelingTest

using TestSetup, OnlineStats, FactCheck, GLM
import OnlineStats: _j, add_deriv

facts(@title "Modeling") do
    context(@subtitle "sweep! operator") do
        x = randn(100, 10)
        A = x'x
        B = x'x
        sweep!(A, 2:4)
        sweep!(A, 2:4, true)
        @fact A --> roughly(B)
        v = zeros(10)
        sweep!(A, 1:5, v)
        sweep!(A, 1:5, v, true)
        @fact A --> roughly(B)
    end

    context(@subtitle "LinReg") do
        n, p = 10000, 10
        x = randn(n, p)
        β = collect(1.:p)
        y = x * β + randn(n)
        o = LinReg(x, y)
        @fact coef(o) --> roughly(x \ y)
        o2 = LinReg(10)
        fit!(o2, x[1:500, :], y[1:500], 500)
        fit!(o2, x[501:1000, :], y[501:1000], 1)
        @fact coef(o) --> roughly(coef(o2), .5)

        l = lm(x, y)
        @fact predict(l, x) --> roughly(predict(o, x))
        @fact predict(l, vec(x[1, :])') --> roughly([predict(o, vec(x[1, :]))])
        @fact loss(o, x, y) --> roughly(mean(abs2(y - x*coef(o))))

        ltab = coeftable(l)
        otab = coeftable(o)
        @fact otab.mat[1:10] --> roughly(ltab.mat[1:10])
        @fact otab.colnms --> ltab.colnms
        @fact otab.rownms --> ltab.rownms
        @fact otab.pvalcol --> roughly(ltab.pvalcol)

        @fact vcov(o)[1:5] --> roughly(vcov(l)[1:5], .001)
        @fact stderr(o)[1:5] --> roughly(stderr(l)[1:5], .001)
        @fact confint(o)[1:5] --> roughly(confint(l)[1:5], .001)

        coef(o, NoPenalty())
        coef(o, L1Penalty(.1))
        coef(o, L2Penalty(.1))
        coef(o, ElasticNetPenalty(.1, .5))
        coef(o, SCADPenalty(.1, 3.7))
    end

    context(@subtitle "Penalty") do
        NoPenalty()
        L1Penalty(.1)
        L2Penalty(.1)
        p = ElasticNetPenalty(.1, .5)
        p2 = SCADPenalty(.1)

        β = randn(5)
        @fact _j(NoPenalty(), β) --> 0.0
        @fact _j(L1Penalty(.1), β) --> .1 * sumabs(β)
        @fact _j(L2Penalty(.1), β) --> 0.5 * .1 * sumabs2(β)
        @fact _j(p, β) --> .1 * (p.α * sumabs(β) + (1 - p.α) * 0.5 * sumabs2(β))
        @fact _j(p2, .01) --> .1 *.01

        p3 = SCADPenalty(.2)
        g = randn()
        βj = randn()
        λ = rand()
        @fact add_deriv(NoPenalty(), g, βj) --> g
        @fact add_deriv(L2Penalty(λ), g, βj) --> g + λ * βj
        @fact add_deriv(L1Penalty(λ), g, βj) --> g + λ * sign(βj)
        @fact add_deriv(p, g, βj) --> g + p.λ * (p.α * sign(βj) + (1 - p.α) * βj)
        @fact add_deriv(p3, g, .1) --> g + .2
        @fact add_deriv(p3, g, .2) --> g + max(3.7 * .2 - .2, 0.0) / (3.7 - 1.0)
        @fact add_deriv(p3, g, 20) --> g
    end

    context(@subtitle "QuantReg") do
        n, p = 10000, 10
        x = randn(n, p)
        β = collect(1.:p)
        y = x * β + randn(n)

        o = QuantReg(x, y)
        fit!(o, x, y, 10)

        @fact coef(o) --> value(o)
        @fact value(o) --> o.β
    end

    context(@subtitle "BiasVector / BiasMatrix") do
        x = randn(100, 10)
        y = randn(100)
        yb = BiasVector(y)
        xb = BiasMatrix(x)

        @fact length(yb) --> 101
        @fact size(yb) --> (101,)
        @fact length(xb) --> 100 * 10 + 100
        @fact size(xb) --> (100, 11)
        @fact yb[101] --> 1
        @fact xb[1, 11] --> 1
        xb[1, 1] = 2.0
        yb[1] = 2.0
        @fact xb[1, 1] --> 2.0
        @fact yb[1] --> 2.0
    end
end

end#module
