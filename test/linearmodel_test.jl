module LinearModelTest

using OnlineStats
using FactCheck
using GLM
using StatsBase

facts("LinearModel") do
    n = rand(1:100_000)
    p = rand(1:min(n-1, 100))

    x = randn(n, p)
    β = [1:p]
    y = x * β + randn(n)

    # First batch accuracy
    obj = LinReg(x, y)
    glm = lm(x, y)
    @fact coef(obj) => roughly(coef(glm))
end

end # module
