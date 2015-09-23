module SGModelTuneTest

using OnlineStats,FactCheck, Compat, Distributions

function linearmodeldata(n, p)
    x = randn(n, p)
    β = (collect(1:p) - .5*p) / p
    y = x*β + randn(n)
    (β, x, y)
end

facts("SGModelTune") do
    n, p = 10_000, 10
    β, x, y = linearmodeldata(n, p)
    o = SGModel(p)
    ocv = SGModelTune(o, decay = .9)
    update!(ocv, x, y)
    @fact nobs(o) --> nobs(ocv)
    @fact coef(o) --> coef(ocv)

    o = SGModel(p, penalty = L1Penalty(.1))
    ocv = SGModelTune(o, decay = .9)
    update!(ocv, x, y)
    @fact nobs(o) --> nobs(ocv)
    @fact coef(o) --> coef(ocv)

    o = SGModel(p, penalty = L2Penalty(.1))
    ocv = SGModelTune(o, decay = .9)
    update!(ocv, x, y)
    @fact nobs(o) --> nobs(ocv)
    @fact coef(o) --> coef(ocv)
end

end #module
