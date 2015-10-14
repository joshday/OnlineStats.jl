module StochasticModelCVTest

using FactCheck, Compat, Distributions, StatsBase
import OnlineStats
O = OnlineStats

# generated data where columns i, j have correlation ρ^abs(i - j)
# Generating correlated predictors to see how well StochasticModel works
function linearmodeldata(n, p, corr = 0)
    V = zeros(p, p)
    for j in 1:p, i in 1:p
        V[i, j] = 8*corr^abs(i - j)
    end
    x = rand(MvNormal(ones(p), V), n)'
    β = vcat(1.:5, zeros(p-5))
    y = x*β + 10*randn(n)
    (β, x, y)
end

facts("StochasticModelCV") do
    n, p = 5_000, 500
    ρ = .9 # correlations
    β, x, y = linearmodeldata(n, p, ρ)
    _, xtest, ytest = linearmodeldata(1000, p, ρ)

    constructor_test = O.StochasticModelCV(x, y, xtest, ytest, penalty = O.L2Penalty(.1))

    o = O.StochasticModel(p, penalty = O.L1Penalty(.1), algorithm = O.RDA())
    ocv = O.StochasticModelCV(o, xtest, ytest)
    O.update!(ocv, x, y)

    println(o.penalty)
    println()

    onotcv = O.StochasticModel(x, y, algorithm = O.RDA())
    lm = O.LinReg(x, y)

    println("rmse truth:     ", O.rmse(xtest * β, ytest))
    println("rmse cv fit:    ", O.rmse(predict(o, xtest), ytest))
    println("rmse fit:       ", O.rmse(predict(onotcv, xtest), ytest))
    println("rmse LinReg:    ", O.rmse(predict(lm, xtest), ytest))
end

facts("StochasticModelCV: L2Regression") do
    n, p = 5_000, 500
    corr = .7
    β, x, y = linearmodeldata(n, p, corr)
    _, xtest, ytest = linearmodeldata(1000, p, corr)
    context("NoPenalty") do
        o1 = O.StochasticModel(x, y, model = O.L2Regression(), algorithm = O.ProxGrad())
        o2 = O.StochasticModel(p, model = O.L2Regression(), algorithm = O.ProxGrad())
        ocv = O.StochasticModelCV(o2, xtest, ytest)
        O.update!(ocv, x, y)
    end
    context("L1Penalty") do
        o1 = O.StochasticModel(x, y, model = O.L2Regression(), algorithm = O.RDA())
        o2 = O.StochasticModel(p, model = O.L2Regression(), algorithm = O.RDA(), penalty = O.L1Penalty(10))
        ocv = O.StochasticModelCV(o2, xtest, ytest)
        O.update!(ocv, x, y)
    end
    context("L2Penalty") do
        o1 = O.StochasticModel(x, y, model = O.L2Regression(), algorithm = O.ProxGrad())
        o2 = O.StochasticModel(p, model = O.L2Regression(), algorithm = O.ProxGrad(), penalty = O.L2Penalty(.1))
        ocv = O.StochasticModelCV(o2, xtest, ytest)
        O.update!(ocv, x, y)
    end
    context("ElasticNetPenalty") do
        o1 = O.StochasticModel(x, y, model = O.L2Regression(), algorithm = O.ProxGrad())
        o2 = O.StochasticModel(p, model = O.L2Regression(), algorithm = O.ProxGrad(), penalty = O.ElasticNetPenalty(.1, .5))
        ocv = O.StochasticModelCV(o2, xtest, ytest)
        O.update!(ocv, x, y)
    end
    context("SCADPenalty") do
        o1 = O.StochasticModel(x, y, model = O.L2Regression(), algorithm = O.ProxGrad())
        o2 = O.StochasticModel(p, model = O.L2Regression(), algorithm = O.ProxGrad(), penalty = O.SCADPenalty(.1))
        ocv = O.StochasticModelCV(o2, xtest, ytest)
        O.update!(ocv, x, y)
    end
end

facts("StochasticModelCV: L1Regression") do
    n, p = 5_000, 500
    corr = .7
    β, x, y = linearmodeldata(n, p, corr)
    _, xtest, ytest = linearmodeldata(1000, p, corr)
    o1 = O.StochasticModel(x, y, model = O.L1Regression(), algorithm = O.ProxGrad())
    o2 = O.StochasticModel(p, model = O.L1Regression(), algorithm = O.ProxGrad())
    ocv = O.StochasticModelCV(o2, xtest, ytest)
    O.update!(ocv, x, y)
end

facts("StochasticModelCV: LogisticRegression") do
end
facts("StochasticModelCV: SVMLike") do
end
facts("StochasticModelCV: PoissonRegression") do
end

facts("StochasticModelCV: HuberRegression") do
    n, p = 5_000, 500
    corr = .7
    β, x, y = linearmodeldata(n, p, corr)
    _, xtest, ytest = linearmodeldata(1000, p, corr)
    o1 = O.StochasticModel(x, y, model = O.HuberRegression(5.), algorithm = O.ProxGrad())
    o2 = O.StochasticModel(p, model = O.HuberRegression(5.), algorithm = O.ProxGrad())
    ocv = O.StochasticModelCV(o2, xtest, ytest)
    O.update!(ocv, x, y)
end

facts("StochasticModelCV: QuantileRegression") do
    n, p = 5_000, 500
    corr = .7
    β, x, y = linearmodeldata(n, p, corr)
    _, xtest, ytest = linearmodeldata(1000, p, corr)
    o1 = O.StochasticModel(x, y, model = O.QuantileRegression(.8), algorithm = O.ProxGrad())
    o2 = O.StochasticModel(p, model = O.QuantileRegression(.8), algorithm = O.ProxGrad())
    ocv = O.StochasticModelCV(o2, xtest, ytest)
    O.update!(ocv, x, y)
end


end #module
