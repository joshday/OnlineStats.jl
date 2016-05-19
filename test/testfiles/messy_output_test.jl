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

    display(BernoulliBootstrap(Mean(), mean, 1000))

    println()
end

end#module
