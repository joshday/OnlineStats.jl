module StochasticModelTest

using OnlineStats, FactCheck, Distributions

function linearmodeldata(n, p)
    x = randn(n, p)
    β = (collect(1:p) - .5*p) / p
    y = x*β + randn(n)
    (β, x, y)
end

function logisticdata(n, p)
    x = randn(n, p)
    β = (collect(1:p) - .5*p) / p
     y = Float64[rand(Bernoulli(i)) for i in 1./(1 + exp(-x*β))]
    (β, x, y)
end

function poissondata(n, p)
    x = randn(n, p)
    β = (collect(1:p) - .5*p) / p
    y = Float64[rand(Poisson(exp(η))) for η in x*β]
    (β, x, y)
end

facts("ModelDefinition Methods") do

    y, eta = randn(2)


    context("loss") do
        @fact loss(L1Regression(), y, eta) --> abs(y - eta)
        @fact loss(L2Regression(), y, eta) --> abs2(y - eta)
        @fact loss(LogisticRegression(), y, eta) --> -y * eta + log(1 + exp(eta))
        @fact loss(PoissonRegression(), y, eta) --> -y * eta + exp(eta)
        @fact loss(QuantileRegression(), y, eta) --> (y - eta) * (0.5 - Float64(y < eta))
        @fact loss(SVMLike(), y, eta) --> max(0.0, 1.0 - y * eta)
        @fact loss(HuberRegression(2.), y, eta) --> (abs(y-eta) < 2. ? 0.5 * (y-eta)^2 : 2. * (abs(y-eta) - 0.5 * 2.))
    end

    context("classify") do
        @fact classify(LogisticRegression(), ones(2), ones(2), 0.0) --> 1.0
        @fact classify(LogisticRegression(), ones(2), -ones(2), 0.0) --> 0.0
        @fact classify(SVMLike(), ones(2), ones(2), 0.0) --> 1.0
        @fact classify(SVMLike(), ones(2), -ones(2), 0.0) --> 0.0

        n, p = 100_000, 20
        β, x, y = logisticdata(n, p)
        o = StochasticModel(x, y, model = LogisticRegression())
        classify(o, x)
        classify(o, vec(x[1, :]))
    end

    context("penalty") do
        p = L1Penalty(.1)
        copy(p)

        @fact OnlineStats._j(NoPenalty(), ones(5)) --> 0.0
        @fact OnlineStats._j(L1Penalty(.1), ones(5)) --> .1 * 5
        @fact OnlineStats._j(L2Penalty(.1), ones(5)) --> .1 * 2.5
        @fact OnlineStats._j(ElasticNetPenalty(.1, .5), ones(5)) --> .1 * (5/2 + 2.5/2)
        @fact OnlineStats._j(SCADPenalty(.1, 3), ones(5)) --> .1^2 * .5 * 4 * 5

        g = randn()
        @fact OnlineStats.add∇j(NoPenalty(), g, ones(5), 1) --> g
        @fact OnlineStats.add∇j(L1Penalty(.1), g, ones(5), 1) --> g + .1
        @fact OnlineStats.add∇j(L2Penalty(.1), g, ones(5), 1) --> g + .1
        @fact OnlineStats.add∇j(ElasticNetPenalty(.1, .5), g, ones(5), 1) --> g + .1
        @fact OnlineStats.add∇j(SCADPenalty(.1, 3), g, ones(5), 1) --> g
        @fact OnlineStats.add∇j(SCADPenalty(.1, 3), g, ones(5) * .001, 1) --> g + .1
        @fact OnlineStats.add∇j(SCADPenalty(.1, 3), g, ones(5) * .2, 1) --> roughly(g + .1 / 2.)
    end
end

end # module
