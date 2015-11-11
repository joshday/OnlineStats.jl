module SGDTest

using OnlineStats,FactCheck, Compat, Distributions

function linearmodeldata(n, p)
    x = randn(n, p)
    β = (collect(1:p) - .5*p) / p
    y = x*β + randn(n)
    (β, x, y)
end

function logisticdata(n, p)
    x = randn(n, p)
    β = (collect(1:p) - .5*p) / p
     y = @compat Float64[rand(Bernoulli(i)) for i in 1./(1 + exp(-x*β))]
    (β, x, y)
end

function poissondata(n, p)
    x = randn(n, p)
    β = (collect(1:p) - .5*p) / p
    y = @compat Float64[rand(Poisson(exp(η))) for η in x*β]
    (β, x, y)
end

facts("SGD") do
    n, p = 100_000, 20
    β, x, y = linearmodeldata(n, p)

    ############################################################### L2Regression
    print_with_color(:blue, " * L2Regression * \n")
    context("NoPenalty") do
        o = StochasticModel(x, y, model = L2Regression(), penalty = NoPenalty())
        predict(o, x)
        @fact length(coef(o)) --> p + 1
        state(o)
        @fact statenames(o) --> [:β, :nobs]

        o = StochasticModel(x, y, model = L2Regression(), penalty = NoPenalty(), intercept = false)
        @fact length(coef(o)) --> p
    end
    context("L1Penalty") do
        o = StochasticModel(x, y, model = L2Regression(), penalty = L1Penalty(.1), algorithm = SGD(LearningRate(), prox = false))
        predict(o, x)
        update!(o, x, y, 100)
    end
    context("L2Penalty") do
        o = StochasticModel(x, y, model = L2Regression(), penalty = L2Penalty(.1))
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = StochasticModel(x, y, model = L2Regression(), penalty = ElasticNetPenalty(.1, .5))
        predict(o, x)
    end
    context("SCADPenalty") do
        o = StochasticModel(x, y, model = L2Regression(), penalty = SCADPenalty(.1, 3.7))
        predict(o, x)
    end




    ############################################################### L1Regression
    print_with_color(:blue, " * L1Regression * \n")
    context("NoPenalty") do
        o = StochasticModel(x, y, model = L1Regression(), penalty = NoPenalty())
        predict(o, x)
    end
    context("L1Penalty") do
        o = StochasticModel(x, y, model = L1Regression(), penalty = L1Penalty(.1))
        predict(o, x)
    end
    context("L2Penalty") do
        o = StochasticModel(x, y, model = L1Regression(), penalty = L2Penalty(.1))
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = StochasticModel(x, y, model = L1Regression(), penalty = ElasticNetPenalty(.1, .5))
        predict(o, x)
    end



    ######################################################### QuantileRegression
    print_with_color(:blue, " * QuantileRegression * \n")
    context("NoPenalty") do
        o = StochasticModel(x, y, model = QuantileRegression(.5), penalty = NoPenalty())
        predict(o, x)
    end
    context("L1Penalty") do
        o = StochasticModel(x, y, model = QuantileRegression(.5), penalty = L1Penalty(.1))
        predict(o, x)
    end
    context("L2Penalty") do
        o = StochasticModel(x, y, model = QuantileRegression(.5), penalty = L2Penalty(.1))
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = StochasticModel(x, y, model = QuantileRegression(.5), penalty = ElasticNetPenalty(.1, .5))
        predict(o, x)
    end



    ############################################################ HuberRegression
    print_with_color(:blue, " * HuberRegression * \n")
    context("NoPenalty") do
        o = StochasticModel(x, y, model = HuberRegression(.5), penalty = NoPenalty())
        predict(o, x)
    end
    context("L1Penalty") do
        o = StochasticModel(x, y, model = HuberRegression(.5), penalty = L1Penalty(.1))
        predict(o, x)
    end
    context("L2Penalty") do
        o = StochasticModel(x, y, model = HuberRegression(.5), penalty = L2Penalty(.1))
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = StochasticModel(x, y, model = HuberRegression(.5), penalty = ElasticNetPenalty(.1, .5))
        predict(o, x)
    end



    β, x, y = logisticdata(n, p)
    ######################################################### LogisticRegression
    print_with_color(:blue, " * LogisticRegression * \n")
    context("NoPenalty") do
        o = StochasticModel(x, y, model = LogisticRegression(), penalty = NoPenalty())
        predict(o, x)
    end
    context("L1Penalty") do
        o = StochasticModel(x, y, model = LogisticRegression(), penalty = L1Penalty(.1))
        predict(o, x)
    end
    context("L2Penalty") do
        o = StochasticModel(x, y, model = LogisticRegression(), penalty = L2Penalty(.1))
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = StochasticModel(x, y, model = LogisticRegression(), penalty = ElasticNetPenalty(.1, .5))
        predict(o, x)
    end



    β, x, y = poissondata(n, p)
    ########################################################## PoissonRegression
    print_with_color(:blue, " * PoissonRegression * \n")
    context("NoPenalty") do
        o = StochasticModel(x, y, model = PoissonRegression(), penalty = NoPenalty(), algorithm = SGD(η = .1))
        predict(o, x)
    end
    context("L1Penalty") do
        o = StochasticModel(x, y, model = PoissonRegression(), penalty = L1Penalty(.1), algorithm = SGD(η = .1))
        predict(o, x)
    end
    context("L2Penalty") do
        o = StochasticModel(x, y, model = PoissonRegression(), penalty = L2Penalty(.1), algorithm = SGD(η = .1))
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = StochasticModel(x, y, model = PoissonRegression(), penalty = ElasticNetPenalty(.1, .5), algorithm = SGD(η = .1))
        predict(o, x)
    end



    #################################################################### SVMLike
    print_with_color(:blue, " * SVMLike * \n")
    y = 2y - 1
    context("NoPenalty") do
        o = StochasticModel(x, y, model = SVMLike(), penalty = NoPenalty())
        predict(o, x)
    end
    context("L1Penalty") do
        o = StochasticModel(x, y, model = SVMLike(), penalty = L1Penalty(.1))
        predict(o, x)
    end
    context("L2Penalty") do
        o = StochasticModel(x, y, model = SVMLike(), penalty = L2Penalty(.1))
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = StochasticModel(x, y, model = SVMLike(), penalty = ElasticNetPenalty(.1, .5))
        predict(o, x)
    end
end

end #module
