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
    display(QuantReg(5))
    display(KMeans(5, 4))
    display(NormalMix(4))

    display(FitCategorical())
    display(FitBeta())

    display(NoPenalty())
    display(LassoPenalty(.1))
    display(RidgePenalty(.1))
    display(ElasticNetPenalty(.1, .5))
    display(SCADPenalty(.1, 3.7))

    display(L2Regression())
    display(L1Regression())
    display(LogisticRegression())
    display(PoissonRegression())
    display(QuantileRegression(.7))
    display(HuberRegression(2))
    display(SVMLike())
    display(StatLearn(10))
    display(StatLearnSparse(StatLearn(10), HardThreshold()))
    display(StatLearnCV(StatLearn(5), randn(100, 5), randn(100)))

    display(BernoulliBootstrap(Mean(), mean, 1000))

    println()
end

end#module
