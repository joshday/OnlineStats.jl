module SGModelCVTest

using FactCheck, Compat, Distributions, StatsBase
import OnlineStats
O = OnlineStats

# generated data where columns i, j have correlation ρ^abs(i - j)
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

    o = O.SGModel(p, penalty = O.L1Penalty(.1), algorithm = O.RDA())
    ocv = O.SGModelCV(o, xtest, ytest, decay = .9)
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

end #module
