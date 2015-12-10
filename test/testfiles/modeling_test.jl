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

        coef(o, .1, NoPenalty())
        coef(o, .1, L1Penalty())
        coef(o, .1, L2Penalty())
        coef(o, .1, ElasticNetPenalty())
        coef(o, .1, SCADPenalty())
    end

    context(@subtitle "Penalty") do
        NoPenalty()
        L1Penalty()
        L2Penalty()
        p = ElasticNetPenalty()

        β = randn(5)
        @fact _j(NoPenalty(), .1, β) --> 0.0
        @fact _j(L1Penalty(), .1, β) --> .1 * sumabs(β)
        @fact _j(L2Penalty(), .1, β) --> 0.5 * .1 * sumabs2(β)
        @fact _j(p, .1, β) --> .1 * (p.α * sumabs(β) + (1 - p.α) * 0.5 * sumabs2(β))

        g = randn()
        βj = randn()
        λ = rand()
        @fact add_deriv(NoPenalty(), g, λ, βj) --> g
        @fact add_deriv(L2Penalty(), g, λ, βj) --> g + λ * βj
        @fact add_deriv(L1Penalty(), g, λ, βj) --> g + λ * sign(βj)
        p = ElasticNetPenalty()
        @fact add_deriv(p, g, λ, βj) --> g + λ * (p.α * sign(βj) + (1 - p.α) * βj)
    end
end

end#module
