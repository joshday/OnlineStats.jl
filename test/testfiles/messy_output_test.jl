module MessyOutput
using OnlineStats, Base.Test, Distributions

x = randn(500)
x1 = randn(500)
x2 = randn(501)
xs = hcat(x1, x)

@testset "show methods" begin
    display(Mean(x))
    display(Means(xs))
    display(Variance(x))
    display(Variances(xs))
    display(CovMatrix(xs))
    display(Extrema(x))
    display(QuantileSGD(x))
    display(QuantileMM(x))
    display(Moments(x))
    display(KMeans(5, 4))
    display(NormalMix(4))
    display(FitCategorical())
    display(FitBeta())
    display(BernoulliBootstrap(Mean(), mean, 1000))
end

end#module
