module Experimental
reload("OnlineStats")
using OnlineStats
O = OnlineStats

using DataGenerator, GLM

x, y, β = logregdata(1_000_000, 5, false)

@time o = O.LogRegMM(x, y, LearningRate(.5))
o2 = StatLearn(x, y, LearningRate(.5), LogisticRegression(), AdaGrad(); intercept = false)
o3 = glm(x, y, Binomial())

@show coef(o)
@show coef(o2)
@show coef(o3)
end
