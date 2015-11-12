module MMGradTest

using OnlineStats,FactCheck, Distributions

function linearmodeldata(n, p)
    x = randn(n, p)
    β = (collect(1:p) - .5*p) / p
    y = x*β + randn(n)
    (β, x, y)
end

function logisticdata(n, p)
    x = randn(n, p)
    β = (collect(1:p) - .5*p) / p
     y = Float64[rand(Bernoulli(i)) for i in 1./(1 + exp(-x*β))]
    (β, x, y)
end

function poissondata(n, p)
    x = randn(n, p)
    β = (collect(1:p) - .5*p) / p
    y = Float64[rand(Poisson(exp(η))) for η in x*β]
    (β, x, y)
end

facts("MMGrad") do
    MMGrad()
    MMGrad(LearningRate())

    n, p = 100_000, 20
    context("L2Regression") do
        β, x, y = linearmodeldata(n, p)
        o = StochasticModel(x, y, algorithm = MMGrad())
        weight(o) = o.algorithm.η * weight(o.algorithm.weighting, o.algorithm.n_updates, 1)
    end
    context("LogisticRegression") do
        β, x, y = logisticdata(n, p)
        o = StochasticModel(x, y, algorithm = MMGrad(), model = LogisticRegression())
    end
    context("PoissonRegression") do
        β, x, y = poissondata(n, p)
        o = StochasticModel(x, y, algorithm = MMGrad(), model = PoissonRegression())
    end
    context("QuantileRegression") do
        β, x, y = linearmodeldata(n, p)
        o = StochasticModel(x, y, algorithm = MMGrad(), model = QuantileRegression())
    end

end

end #module
