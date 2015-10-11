module SGModelCVTest

using FactCheck, Compat, Distributions, StatsBase
import OnlineStats
O = OnlineStats

# generated data where columns i, j have correlation ρ^abs(i - j)
# Generating correlated predictors to see how well SGModelCV works
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

facts("SGModelCV") do
    n, p = 5_000, 500
    ρ = .9 # correlations
    β, x, y = linearmodeldata(n, p, ρ)
    _, xtest, ytest = linearmodeldata(1000, p, ρ)

    constructor_test = O.SGModelCV(x, y, xtest, ytest, penalty = O.L2Penalty(.1))

    o = O.SGModel(p, penalty = O.L1Penalty(.1), algorithm = O.RDA())
    ocv = O.SGModelCV(o, xtest, ytest)
    O.update!(ocv, x, y)

    println(o.penalty)
    println()

    onotcv = O.SGModel(x, y, algorithm = O.RDA())
    lm = O.LinReg(x, y)

    println("rmse truth:     ", O.rmse(xtest * β, ytest))
    println("rmse cv fit:    ", O.rmse(predict(o, xtest), ytest))
    println("rmse fit:       ", O.rmse(predict(onotcv, xtest), ytest))
    println("rmse LinReg:    ", O.rmse(predict(lm, xtest), ytest))
end

facts("SGModelCV: L2Regression") do
    n, p = 5_000, 500
    corr = .7
    β, x, y = linearmodeldata(n, p, corr)
    _, xtest, ytest = linearmodeldata(1000, p, corr)
    context("NoPenalty") do
        o1 = O.SGModel(x, y, model = O.L2Regression(), algorithm = O.ProxGrad())
        o2 = O.SGModel(p, model = O.L2Regression(), algorithm = O.ProxGrad())
        ocv = O.SGModelCV(o2, xtest, ytest)
        O.update!(ocv, x, y)
        @fact O.loss(o2, xtest, ytest) --> O.loss(o1, xtest, ytest)
    end
    context("L1Penalty") do
        o1 = O.SGModel(x, y, model = O.L2Regression(), algorithm = O.RDA())
        o2 = O.SGModel(p, model = O.L2Regression(), algorithm = O.RDA(), penalty = O.L1Penalty(10))
        ocv = O.SGModelCV(o2, xtest, ytest)
        O.update!(ocv, x, y)
        @fact O.loss(o2, xtest, ytest) -->  less_than(O.loss(o1, xtest, ytest))
    end
    context("L2Penalty") do
        o1 = O.SGModel(x, y, model = O.L2Regression(), algorithm = O.ProxGrad())
        o2 = O.SGModel(p, model = O.L2Regression(), algorithm = O.ProxGrad(), penalty = O.L2Penalty(.1))
        ocv = O.SGModelCV(o2, xtest, ytest)
        O.update!(ocv, x, y)
        @fact O.loss(o2, xtest, ytest) --> less_than(O.loss(o1, xtest, ytest))
    end
    context("ElasticNetPenalty") do
        o1 = O.SGModel(x, y, model = O.L2Regression(), algorithm = O.ProxGrad())
        o2 = O.SGModel(p, model = O.L2Regression(), algorithm = O.ProxGrad(), penalty = O.ElasticNetPenalty(.1, .5))
        ocv = O.SGModelCV(o2, xtest, ytest)
        O.update!(ocv, x, y)
        @fact O.loss(o2, xtest, ytest) --> less_than(O.loss(o1, xtest, ytest))
    end
    context("SCADPenalty") do
        o1 = O.SGModel(x, y, model = O.L2Regression(), algorithm = O.ProxGrad())
        o2 = O.SGModel(p, model = O.L2Regression(), algorithm = O.ProxGrad(), penalty = O.SCADPenalty(.1))
        ocv = O.SGModelCV(o2, xtest, ytest)
        O.update!(ocv, x, y)
        @fact O.loss(o2, xtest, ytest) --> less_than(O.loss(o1, xtest, ytest))
    end
end

facts("SGModelCV: L1Regression") do
    n, p = 5_000, 500
    corr = .7
    β, x, y = linearmodeldata(n, p, corr)
    _, xtest, ytest = linearmodeldata(1000, p, corr)
    o1 = O.SGModel(x, y, model = O.L1Regression(), algorithm = O.ProxGrad())
    o2 = O.SGModel(p, model = O.L1Regression(), algorithm = O.ProxGrad())
    ocv = O.SGModelCV(o2, xtest, ytest)
    O.update!(ocv, x, y)
    @fact O.loss(o2, xtest, ytest) --> O.loss(o1, xtest, ytest)
end

facts("SGModelCV: LogisticRegression") do
end
facts("SGModelCV: SVMLike") do
end
facts("SGModelCV: PoissonRegression") do
end

facts("SGModelCV: HuberRegression") do
    n, p = 5_000, 500
    corr = .7
    β, x, y = linearmodeldata(n, p, corr)
    _, xtest, ytest = linearmodeldata(1000, p, corr)
    o1 = O.SGModel(x, y, model = O.HuberRegression(5.), algorithm = O.ProxGrad())
    o2 = O.SGModel(p, model = O.HuberRegression(5.), algorithm = O.ProxGrad())
    ocv = O.SGModelCV(o2, xtest, ytest)
    O.update!(ocv, x, y)
    @fact O.loss(o2, xtest, ytest) --> O.loss(o1, xtest, ytest)
end

facts("SGModelCV: QuantileRegression") do
    n, p = 5_000, 500
    corr = .7
    β, x, y = linearmodeldata(n, p, corr)
    _, xtest, ytest = linearmodeldata(1000, p, corr)
    o1 = O.SGModel(x, y, model = O.QuantileRegression(.8), algorithm = O.ProxGrad())
    o2 = O.SGModel(p, model = O.QuantileRegression(.8), algorithm = O.ProxGrad())
    ocv = O.SGModelCV(o2, xtest, ytest)
    O.update!(ocv, x, y)
    @fact O.loss(o2, xtest, ytest) --> O.loss(o1, xtest, ytest)
end


end #module
