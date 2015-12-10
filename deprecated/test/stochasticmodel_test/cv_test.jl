module StochasticModelCVTest

using FactCheck, OnlineStats, Distributions, StatsBase

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

    constructor_test = StochasticModelCV(x, y, xtest, ytest, penalty = L2Penalty(.1))

    o = StochasticModel(p, penalty = L1Penalty(.1), algorithm = RDA())
    ocv = StochasticModelCV(o, xtest, ytest)
    update!(ocv, x, y)
    @fact coef(ocv) --> coef(ocv.o)
    @fact statenames(ocv) --> [:β, :penalty, :nobs]
    @fact state(ocv)[1] --> coef(ocv)
    @fact state(ocv)[2].λ --> ocv.o.penalty.λ
    @fact state(ocv)[3] --> nobs(ocv)
    @fact predict(ocv, ones(p)) --> predict(ocv.o, ones(p))

    onotcv = StochasticModel(x, y, algorithm = RDA())
    lm = LinReg(x, y)

    println("OnlineStats.rmse truth:     ", OnlineStats.rmse(xtest * β, ytest))
    println("OnlineStats.rmse cv fit:    ", OnlineStats.rmse(predict(o, xtest), ytest))
    println("OnlineStats.rmse fit:       ", OnlineStats.rmse(predict(onotcv, xtest), ytest))
    println("OnlineStats.rmse LinReg:    ", OnlineStats.rmse(predict(lm, xtest), ytest))
end

facts("StochasticModelCV: L2Regression") do
    n, p = 5_000, 500
    corr = .7
    β, x, y = linearmodeldata(n, p, corr)
    _, xtest, ytest = linearmodeldata(1000, p, corr)
    context("NoPenalty") do
        o1 = StochasticModel(x, y, model = L2Regression(), algorithm = ProxGrad())
        o2 = StochasticModel(p, model = L2Regression(), algorithm = ProxGrad())
        ocv = StochasticModelCV(o2, xtest, ytest)
        update!(ocv, x, y)
    end
    context("L1Penalty") do
        o1 = StochasticModel(x, y, model = L2Regression(), algorithm = RDA())
        o2 = StochasticModel(p, model = L2Regression(), algorithm = RDA(), penalty = L1Penalty(10))
        ocv = StochasticModelCV(o2, xtest, ytest)
        update!(ocv, x, y)
    end
    context("L2Penalty") do
        o1 = StochasticModel(x, y, model = L2Regression(), algorithm = ProxGrad())
        o2 = StochasticModel(p, model = L2Regression(), algorithm = ProxGrad(), penalty = L2Penalty(.1))
        ocv = StochasticModelCV(o2, xtest, ytest)
        update!(ocv, x, y)
    end
    context("ElasticNetPenalty") do
        o1 = StochasticModel(x, y, model = L2Regression(), algorithm = ProxGrad())
        o2 = StochasticModel(p, model = L2Regression(), algorithm = ProxGrad(), penalty = ElasticNetPenalty(.1, .5))
        ocv = StochasticModelCV(o2, xtest, ytest)
        update!(ocv, x, y)
    end
    context("SCADPenalty") do
        o1 = StochasticModel(x, y, model = L2Regression(), algorithm = ProxGrad())
        o2 = StochasticModel(p, model = L2Regression(), algorithm = ProxGrad(), penalty = SCADPenalty(.1))
        ocv = StochasticModelCV(o2, xtest, ytest)
        update!(ocv, x, y)
    end
end

facts("StochasticModelCV: L1Regression") do
    n, p = 5_000, 500
    corr = .7
    β, x, y = linearmodeldata(n, p, corr)
    _, xtest, ytest = linearmodeldata(1000, p, corr)
    o1 = StochasticModel(x, y, model = L1Regression(), algorithm = ProxGrad())
    o2 = StochasticModel(p, model = L1Regression(), algorithm = ProxGrad())
    ocv = StochasticModelCV(o2, xtest, ytest)
    update!(ocv, x, y)
end

# facts("StochasticModelCV: LogisticRegression") do
# end
# facts("StochasticModelCV: SVMLike") do
# end
# facts("StochasticModelCV: PoissonRegression") do
# end

facts("StochasticModelCV: HuberRegression") do
    n, p = 5_000, 500
    corr = .7
    β, x, y = linearmodeldata(n, p, corr)
    _, xtest, ytest = linearmodeldata(1000, p, corr)
    o1 = StochasticModel(x, y, model = HuberRegression(5.), algorithm = ProxGrad())
    o2 = StochasticModel(p, model = HuberRegression(5.), algorithm = ProxGrad())
    ocv = StochasticModelCV(o2, xtest, ytest)
    update!(ocv, x, y)
end

facts("StochasticModelCV: QuantileRegression") do
    n, p = 5_000, 500
    corr = .7
    β, x, y = linearmodeldata(n, p, corr)
    _, xtest, ytest = linearmodeldata(1000, p, corr)
    o1 = StochasticModel(x, y, model = QuantileRegression(.8), algorithm = ProxGrad())
    o2 = StochasticModel(p, model = QuantileRegression(.8), algorithm = ProxGrad())
    ocv = StochasticModelCV(o2, xtest, ytest)
    update!(ocv, x, y)
end


end #module
