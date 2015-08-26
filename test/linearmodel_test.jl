module LinearModelTest

using OnlineStats, FactCheck, GLM, StatsBase

facts("Linear Model") do
    context("LinReg") do
        n = rand(10_000:100_000)
        p = rand(1:min(n-1, 100))

        x = randn(n, p)
        β = collect(1:p)
        y = x * β + randn(n)

        # First batch accuracy
        o = LinReg(x, y)
        glm = lm(x, y)
        @fact coef(o) --> roughly(coef(glm))
        @fact statenames(o) --> [:β, :nobs]
        @fact state(o)[1] --> coef(o)
        @fact state(o)[2] --> nobs(o)
        @fact OnlineStats.mse(o) --> roughly( sum( (y - x * coef(o)) .^ 2 ) / (n - p), 1e-3)
        @fact OnlineStats.mse(o) --> roughly( sum( (y - predict(o, x)) .^ 2 ) / (n - p), 1e-3)
        @fact stderr(o) --> roughly(stderr(glm), 1e-3)
        @fact maxabs(vcov(o) - vcov(glm)) --> roughly(0, 1e-5)

        x = rand(10_000, 2)
        β = ones(2)
        y = x*β + randn(10_000)
        o = LinReg(x, y)
        glm = lm(x, y)

        ct1 = coeftable(o)
        ct2 = coeftable(glm)
        @fact ct1.pvalcol --> ct2.pvalcol
        @fact ct1.colnms --> ct2.colnms
        @fact ct1.rownms --> ct2.rownms
        @fact ct1.mat - ct2.mat --> roughly(zeros(2, 4), .01)
        @fact confint(o) --> roughly(confint(glm), .001)

        β = ones(10)
        x = randn(100, 10)
        y = x*β + randn(100)
        o = LinReg(x, y)
        for i in 1:10_000
            randn!(x)
            y = x*β + randn(100)
            updatebatch!(o, x, y)
        end
        @fact coef(o) --> roughly(ones(10), .01)
        @fact predict(o, x) --> x * coef(o)
        @fact predict(o, ones(10)) --> dot(ones(10), coef(o))

        # update! vs updatebatch!
        o1 = OnlineStats.LinReg(10)
        o2 = OnlineStats.LinReg(10)

        x = randn(10000, 10)
        y = x*β + randn(10000)
        OnlineStats.updatebatch!(o1, x, y)
        OnlineStats.update!(o2, x, y)
        @fact coef(o1) --> roughly(coef(o2), .1)

        o1 = OnlineStats.LinReg(10)
        o2 = OnlineStats.LinReg(10)
        OnlineStats.update!(o1, vec(x[1,:]), y[1])
        OnlineStats.update!(o2, x[1,:], collect(y[1]))
        @fact mean(o1.c) --> roughly(mean(o2.c))
    end

    context("StepwiseReg") do
        n = 5000
        p = 9
        β = collect(1:p)  # coefs are 1,0,3,0,5,...
        β .*= β .% 2
        x = randn(n, p)
        y = x*β + randn(n)

        # things to add tests for:
        o = OnlineStats.StepwiseReg(p)
        o = OnlineStats.StepwiseReg(x, y)
        OnlineStats.onlinefit!(o, 500, x, y, batch = true)
        state(o)
        statenames(o)
        coef(o)
    end

    context("SparseReg") do
        n, p = 10000, 200
        o = SparseReg(p)

        x = randn(n, p)
        β = [1:5; zeros(p - 5)]
        y = x * β + randn(n)

        updatebatch!(o, x, y)
        @fact coef(o) --> coef(SparseReg(x, y))
        @fact statenames(o) --> [:β, :nobs]
        @fact state(o) --> Any[coef(o), nobs(o)]

        βols = coef(o)
        βlasso = coef(o, :lasso, 1.0, verbose = false)
        for i in 2:p
            @fact abs(βlasso[i]) --> less_than(abs(βols[i]))
        end

        # ols
        glm = lm([ones(n) x],y);
        @fact maxabs(coef(glm) - coef(o)) --> roughly(0., 1e-8)
        @fact_throws coef(o, :asdf, .5)

        # ridge
        for λ in 0.:.1:5.
            lambdamat = eye(p) * λ
            βridge = inv(cor(x) + lambdamat) * vec(cor(x, y))
            μ = mean(o.c)
            σ = std(o.c)
            β₀ = μ[end] - σ[end] * sum(μ[1:end-1] ./ σ[1:end-1] .* βridge)
            βridge = σ[end] * (βridge ./ σ[1:end-1])
            βridge = [β₀; βridge]

            @fact maxabs(coef(o, :ridge, 0.) - coef(o)) --> roughly(0., 1e-8)
            @fact maxabs(coef(o, :ridge, λ) - βridge) --> roughly(0., 1e-8)
        end

        update!(o, ones(p), sum(β))
        update!(o, randn(n, p), x*β + randn(n))

    #     Convex.set_default_solver(SCS.SCSSolver(verbose = 0))
    #     diff = maxabs(coef(o, :ridge, .5) -
    #                       OnlineStats.coef_solver(o, .5, x-> .5 * sum_squares(x)))
    #     @fact diff --> roughly(0., .01)
    end
end
end # module
