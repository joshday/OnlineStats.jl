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
    display(QuantRegMM(5))
    display(KMeans(5, 4))
    display(NormalMix(4))
    display(FitCategorical())
    display(FitBeta())
    display(BernoulliBootstrap(Mean(), mean, 1000))
    display(StatLearn(4))

    @testset "Full Factorial of Combinations" begin
        n, p = 500, 5
        x = randn(n, p)
        β = collect(linspace(-1, 1, p))
        β_with_intercept = vcat(0.0, β)
        xβ = x*β
        alg = [SGD(), AdaGrad(), AdaGrad2(), AdaDelta(), ADAM()] #, RDA(), MMGrad()]
        pen = [NoPenalty(), RidgePenalty(.1), LassoPenalty(.1), ElasticNetPenalty(.1, .5)]
        mod = [
            LinearRegression(), L1Regression(), LogisticRegression(), GDWDLike(1.0),
            PoissonRegression(), QuantileRegression(.5), SVMLike(), HuberRegression(2.)
        ]

        generate(::LinearRegression, xβ) = xβ + randn(size(xβ, 1))
        generate(::L1Regression, xβ) = xβ + randn(size(xβ, 1))
        generate(::LogisticRegression, xβ) = [rand(Bernoulli(1 / (1 + exp(-η)))) for η in xβ]
        generate(::PoissonRegression, xβ) = [rand(Poisson(exp(η))) for η in xβ]
        generate(::QuantileRegression, xβ) = xβ + randn(size(xβ, 1))
        generate(::SVMLike, xβ) = [rand(Bernoulli(1 / (1 + exp(-η)))) for η in xβ]
        generate(::GDWDLike, η) = generate(SVMLike(), η)
        generate(::HuberRegression, xβ) = xβ + randn(size(xβ, 1))

        for a in alg, p in pen, m in mod
            y = generate(m, xβ)
            println(replace("    > $a, $p, $m", "OnlineStats.", ""))
            StatLearn(x, y, m, a, p)
            StatLearn(x, y, 10, m, a, p)
        end
    end
end

end#module
