module AdagradTest
using OnlineStats, FactCheck
# using StreamStats

# TODO compare to StreamStats results
# TODO compare timing to StreamStats and profile

facts("Adagrad") do
    # n = rand(10_000:100_000)
    # p = rand(1:min(n-1, 100))
    n, p = 1_000_000, 10

    context("OLS") do
        x = randn(n, p)
        β = collect(1.:p)
        y = x * β + randn(n)*0


        # normal lin reg
        o = Adagrad(x, y)
        println(o, ": β=", β)
        @fact coef(o) => roughly(β)

        # ridge regression
        # repeat same data in first 2 variables
        # it should give 1.5 for β₁ and β₂ after reg (even though actual betas are 1 and 2)
        x[:,2] = x[:,1]  
        y = x * β
        β2 = vcat(1.5, 1.5, β[3:end])
        o = Adagrad(x, y; reg = L2Reg(0.01))
        println(o, ": β=", β2)
        @fact coef(o) => roughly(β2, atol = 0.2)
    end

    if true
    context("Logistic") do

        x = randn(n, p)
        β = collect(1.:p)
        y = map(y -> y>0.0 ? 1.0 : 0.0, x * β)

        # logistic
        o = Adagrad(x, y; link=LogisticLink(), loss=LogisticLoss())
        println(o, ": β=", β)
        @fact coef(o) => roughly(β, atol = 0.1)

        # logistic l2
        # repeat same data in first 2 variables
        # it should give 1.5 for β₁ and β₂ after reg (even though actual betas are 1 and 2)
        x[:,2] = x[:,1]  
        y = x * β
        β2 = vcat(1.5, 1.5, β[3:end])
        o = Adagrad(x, y; link=LogisticLink(), loss=LogisticLoss(), reg=L2Reg(0.1))
        println(o, ": β=", β2)
        @fact coef(o) => roughly(β2, atol = 0.2)
    end
    end

    # # First batch accuracy
    # o = LinReg(x, y)
    # glm = lm(x, y)
    # @fact coef(o) => roughly(coef(glm))
    # @fact statenames(o) => [:β, :nobs]
    # @fact state(o)[1] => coef(o)
    # @fact state(o)[2] => nobs(o)
    # @fact mse(o) => roughly( sum( (y - x * coef(o)) .^ 2 ) / (n - p), 1e-3)
    # @fact mse(o) => roughly( sum( (y - predict(o, x)) .^ 2 ) / (n - p), 1e-3)
    # @fact stderr(o) => roughly(stderr(glm), 1e-3)
    # @fact maxabs(vcov(o) - vcov(glm)) => roughly(0, 1e-5)

    # x = rand(10_000, 2)
    # β = ones(2)
    # y = x*β + randn(10_000)
    # o = LinReg(x, y)
    # glm = lm(x, y)

    # ct1 = coeftable(o)
    # ct2 = coeftable(glm)
    # @fact ct1.pvalcol => ct2.pvalcol
    # @fact ct1.colnms => ct2.colnms
    # @fact ct1.rownms => ct2.rownms
    # @fact ct1.mat - ct2.mat => roughly(zeros(2, 4), .01)
    # @fact confint(o) => roughly(confint(glm))

    # β = ones(10)
    # x = randn(100, 10)
    # y = x*β + randn(100)
    # o = LinReg(x, y)
    # for i in 1:10_000
    #     randn!(x)
    #     y = x*β + randn(100)
    #     updatebatch!(o, x, y)
    # end
    # @fact coef(o) => roughly(ones(10), .01)
    # @fact predict(o, x) => x * coef(o)
end

end # module
