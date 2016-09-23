module Experimental
reload("OnlineStats")
using OnlineStats
O = OnlineStats

using DataGenerator, GLM

# For testing LogRegMM
x, y, β = logregdata(1_000_000, 5, false)
@time o = O.LogRegMM(x, y, LearningRate(.7))
o2 = StatLearn(x, y, LearningRate(.7), LogisticRegression(), AdaGrad(); intercept = false)
o3 = glm(x, y, Binomial())
@show coef(o)
@show coef(o2)
@show coef(o3)

@show loss(o, x, y)
@show loss(o2, x, y)
# # For Testing QuantRegMM
# x, y, β = linregdat(100_000, 5)
# o = QuantRegMM(x, y, LearningRate(.5))
# o2 = StatLearn(x, y, LearningRate(.5), QuantileRegression(.8))
# @show coef(o)
end
