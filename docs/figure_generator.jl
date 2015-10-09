# This file generates the figures for the docs
using Plots, OnlineStats


#### Show how LearningRate parameters affect weights
f(t, λ, r) = [1. / (1. + λ * ti^r) for ti in t]
x = 0:50
#
# p = plot(
#     hcat(f(x, 1.0, 1.0), f(x, .5, 1.0), f(x, .01, 1.0));
#     xlab = "nobs", ylab = "weight", label = ["λ=1,    r=1" "λ=.5,   r=1" "λ=.01, r=1"]
# )
# savefig(p, "docs/images/learningrate_lambdas.png")

p = plot(
    hcat(f(x, 1.0, 1.0), f(x, 1.0, .75), f(x, 1.0, .5));
    xlab = "nobs", ylab = "weight", label = ["λ=1, r=1" "λ=1, r=.5" "λ=1, r=.01"]
)
title!(p, "Weights for Different LearningRate Parameters")
savefig(p, "docs/images/learningrate_rs.png")



#### traceplot
x = randn(10_000, 10)
β = collect(1:10)
y = x*β + randn(10_000)

# coefficients of a stochastic gradient descent model
o = SGModel(size(x, 2), algorithm = RDA())
p = traceplot!(o, 100, x, y, f = coef)
savefig(p, "docs/images/traceplot.png")
