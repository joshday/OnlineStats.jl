module AdagradTest
using OnlineStats, FactCheck
using Distributions
import StreamStats

# TODO compare to StreamStats results
# TODO compare timing to StreamStats and profile

function convertLogisticY(xβ)
    prob = OnlineStats.invlink(LogisticLink(), xβ)
    Float64(rand(Bernoulli(prob)))
end

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
        @fact predict(o, ones(p)) => roughly(1.0 * sum(β))

        # ridge regression
        # repeat same data in first 2 variables
        # it should give 1.5 for β₁ and β₂ after reg (even though actual betas are 1 and 2)
        x[:,2] = x[:,1]  
        y = x * β
        β2 = vcat(1.5, 1.5, β[3:end])
        o = Adagrad(x, y; reg = L2Reg(0.01))
        println(o, ": β=", β2)
        @fact coef(o) => roughly(β2, atol = 0.2)

        # some simple checks of the interface
        @fact statenames(o) => [:β, :nobs]
        @fact state(o)[1] => coef(o)
        @fact state(o)[2] => nobs(o)

    end

    if true
    context("Logistic") do

        x = randn(n, p)
        β = collect(1.:p)
        # y = map(y -> y>0.0 ? 1.0 : 0.0, x * β)
        y = map(convertLogisticY, x * β)

        # logistic
        o = Adagrad(x, y; link=LogisticLink(), loss=LogisticLoss(), η=1.0)
        println(o, ": β=", β)
        @fact coef(o) => roughly(β, atol = 0.5, rtol = 0.1)

        # logistic l2
        # repeat same data in first 2 variables
        # it should give 1.5 for β₁ and β₂ after reg (even though actual betas are 1 and 2)
        x[:,2] = x[:,1]  
        # y = map(y -> y>0.0 ? 1.0 : 0.0, x * β)
        y = map(convertLogisticY, x * β)
        β2 = vcat(1.5, 1.5, β[3:end])
        o = Adagrad(x, y; link=LogisticLink(), loss=LogisticLoss(), reg=L2Reg(0.00001), η=1.0)
        println(o, ": β=", β2)
        @fact coef(o) => roughly(β2, atol = 0.8, rtol = 0.2)
    end
    end

# # if false

# using OnlineStats
# import StreamStats
# const n = 1_000_000;
# const p = 10;
# const x = randn(n, p);
# const xbias = hcat(ones(n), x);
# const β = collect(1.:p);
# const y = x * β + randn(n)*10;
# ols_ss = StreamStats.ApproxOLS(p)
# do_ss_ols(x, y) = (ols = StreamStats.ApproxOLS(p); for i in 1:n; StreamStats.update!(ols, vec(x[i,:]), y[i]); end; ols)
# do_os_ols(x, y) = (ols = Adagrad(p+1); for i in 1:n; update!(ols, vec(x[i,:]), y[i]); end; ols)
# StreamStats.state(do_ss_ols(x, y))'
# coef(do_os_ols(xbias,y))'
# #warmup complete
# @time do_ss_ols(x,y)
# @time do_os_ols(xbias,y)

# # @time Adagrad(x,y)
# # @time Adagrad(x,y)
# # @profile Adagrad(x,y)

# # @time LinReg(x,y)
# # @time LinReg(x,y)
# # @profile LinReg(x,y)
# # end

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
