########################################################
module Test

using OnlineStats, Distributions

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

n, p = 10_000, 10
β, x, y = linearmodeldata(n,p)
_, x2, y2 = linearmodeldata(1000, p)
@time ocv = StochasticModelCV(x, y, x2, y2, penalty = L1Penalty(.1), algorithm = RDA())
update!(ocv, x, y)
show(ocv)

β, x, y = logisticdata(n, p)
_, x2, y2 = logisticdata(1000, p)
@time ocv = StochasticModelCV(x, 2y-1, x2, y2, penalty = L2Penalty(.1), algorithm = SGD(), model = LogisticRegression(),
    burnin = 9000)
update!(ocv, x, y)
show(ocv)

end
