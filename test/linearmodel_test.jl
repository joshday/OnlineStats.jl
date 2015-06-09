module LinearModelTest

using OnlineStats
using FactCheck
using GLM
using StatsBase

facts("LinearModel") do
    n = rand(10_000:100_000)
    p = rand(1:min(n-1, 100))

    x = randn(n, p)
    β = [1:p]
    y = x * β + randn(n)

    # First batch accuracy
    o = LinReg(x, y)
    glm = lm(x, y)
    @fact coef(o) => roughly(coef(glm))
    @fact statenames(o) => [:β, :nobs]
    @fact state(o)[1] => coef(o)
    @fact state(o)[2] => nobs(o)
    @fact mse(o) => roughly( sum( (y - x * coef(o)) .^ 2 ) / (n - p), 1e-3)
    @fact mse(o) => roughly( sum( (y - predict(o, x)) .^ 2 ) / (n - p), 1e-3)
    @fact stderr(o) => roughly(stderr(glm), 1e-3)
    @fact maxabs(vcov(o) - vcov(glm)) => roughly(0, 1e-5)

    x = rand(10_000, 2)
    β = ones(2)
    y = x*β + randn(10_000)
    o = LinReg(x, y)
    glm = lm(x, y)

    ct1 = coeftable(o)
    ct2 = coeftable(glm)
    @fact ct1.pvalcol => ct2.pvalcol
    @fact ct1.colnms => ct2.colnms
    @fact ct1.rownms => ct2.rownms
    @fact ct1.mat - ct2.mat => roughly(zeros(2, 4), .01)
    @fact confint(o) => roughly(confint(glm))

    β = ones(10)
    x = randn(100, 10)
    y = x*β + randn(100)
    o = LinReg(x, y)
    for i in 1:10_000
        randn!(x)
        y = x*β + randn(100)
        updatebatch!(o, x, y)
    end
    @fact coef(o) => roughly(ones(10), .01)
    @fact predict(o, x) => x * coef(o)
end

end # module
