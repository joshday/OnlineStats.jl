module MessyOutput
# tests for show methods or things that print
# This keeps the other tests look more organized


using TestSetup, OnlineStats, FactCheck, Distributions

x = randn(500)
x1 = randn(500)
x2 = randn(501)
xs = hcat(x1, x)

facts(@title "Show Methods") do
    display(Mean(x))
    display(Means(xs))
    display(Variance(x))
    display(Variances(xs))
    display(CovMatrix(xs))
    display(Extrema(x))
    display(QuantileSGD(x))
    display(QuantileMM(x))
    display(Moments(x))

    display(FitDistribution(Normal, x))
    display(FitMvDistribution(MvNormal, xs))

    display(NoPenalty())
    display(L1Penalty())
    display(L2Penalty())
    display(ElasticNetPenalty())
    display(SCADPenalty())

    display(L2Regression())
    display(L1Regression())
    display(LogisticRegression())
    display(PoissonRegression())
    display(QuantileRegression(.7))
    display(HuberRegression(2))
    display(SVMLike())
    display(StatLearn(10))
end

end#module
