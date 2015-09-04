module ProxgradTest

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

facts("Proxgrad") do
    n, p = 100_000, 20
    β, x, y = linearmodeldata(n, p)

    ############################################################### L2Regression
    print_with_color(:blue, " * L2Regression * \n")
    context("NoPenalty") do
        o = SGModel(x, y, model = L2Regression(), penalty = NoPenalty(), algorithm = Proxgrad())
        predict(o, x)
        @fact length(coef(o)) --> p + 1

        o = SGModel(x, y, model = L2Regression(), penalty = NoPenalty(), intercept = false, algorithm = Proxgrad())
        @fact length(coef(o)) --> p
    end
    context("L1Penalty") do
        o = SGModel(x, y, model = L2Regression(), penalty = L1Penalty(.1), algorithm = Proxgrad())
        predict(o, x)
    end
    context("L2Penalty") do
        o = SGModel(x, y, model = L2Regression(), penalty = L2Penalty(.1), algorithm = Proxgrad())
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = SGModel(x, y, model = L2Regression(), penalty = ElasticNetPenalty(.1, .5), algorithm = Proxgrad())
        predict(o, x)
    end




    ############################################################### L1Regression
    print_with_color(:blue, " * L1Regression * \n")
    context("NoPenalty") do
        o = SGModel(x, y, model = L1Regression(), penalty = NoPenalty(), algorithm = Proxgrad())
        predict(o, x)
    end
    context("L1Penalty") do
        o = SGModel(x, y, model = L1Regression(), penalty = L1Penalty(.1), algorithm = Proxgrad())
        predict(o, x)
    end
    context("L2Penalty") do
        o = SGModel(x, y, model = L1Regression(), penalty = L2Penalty(.1), algorithm = Proxgrad())
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = SGModel(x, y, model = L1Regression(), penalty = ElasticNetPenalty(.1, .5), algorithm = Proxgrad())
        predict(o, x)
    end



    ######################################################### QuantileRegression
    print_with_color(:blue, " * QuantileRegression * \n")
    context("NoPenalty") do
        o = SGModel(x, y, model = QuantileRegression(.5), penalty = NoPenalty(), algorithm = Proxgrad())
        predict(o, x)
    end
    context("L1Penalty") do
        o = SGModel(x, y, model = QuantileRegression(.5), penalty = L1Penalty(.1), algorithm = Proxgrad())
        predict(o, x)
    end
    context("L2Penalty") do
        o = SGModel(x, y, model = QuantileRegression(.5), penalty = L2Penalty(.1), algorithm = Proxgrad())
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = SGModel(x, y, model = QuantileRegression(.5), penalty = ElasticNetPenalty(.1, .5), algorithm = Proxgrad())
        predict(o, x)
    end



    ############################################################ HuberRegression
    print_with_color(:blue, " * HuberRegression * \n")
    context("NoPenalty") do
        o = SGModel(x, y, model = HuberRegression(.5), penalty = NoPenalty(), algorithm = Proxgrad())
        predict(o, x)
    end
    context("L1Penalty") do
        o = SGModel(x, y, model = HuberRegression(.5), penalty = L1Penalty(.1), algorithm = Proxgrad())
        predict(o, x)
    end
    context("L2Penalty") do
        o = SGModel(x, y, model = HuberRegression(.5), penalty = L2Penalty(.1), algorithm = Proxgrad())
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = SGModel(x, y, model = HuberRegression(.5), penalty = ElasticNetPenalty(.1, .5), algorithm = Proxgrad())
        predict(o, x)
    end



    β, x, y = logisticdata(n, p)
    ######################################################### LogisticRegression
    print_with_color(:blue, " * LogisticRegression * \n")
    context("NoPenalty") do
        o = SGModel(x, y, model = LogisticRegression(), penalty = NoPenalty(), algorithm = Proxgrad())
        predict(o, x)
    end
    context("L1Penalty") do
        o = SGModel(x, y, model = LogisticRegression(), penalty = L1Penalty(.1), algorithm = Proxgrad())
        predict(o, x)
    end
    context("L2Penalty") do
        o = SGModel(x, y, model = LogisticRegression(), penalty = L2Penalty(.1), algorithm = Proxgrad())
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = SGModel(x, y, model = LogisticRegression(), penalty = ElasticNetPenalty(.1, .5), algorithm = Proxgrad())
        predict(o, x)
    end



    #################################################################### SVMLike
    print_with_color(:blue, " * SVMLike * \n")
    y = 2y - 1
    context("NoPenalty") do
        o = SGModel(x, y, model = SVMLike(), penalty = NoPenalty(), algorithm = Proxgrad())
        predict(o, x)
    end
    context("L1Penalty") do
        o = SGModel(x, y, model = SVMLike(), penalty = L1Penalty(.1), algorithm = Proxgrad())
        predict(o, x)
    end
    context("L2Penalty") do
        o = SGModel(x, y, model = SVMLike(), penalty = L2Penalty(.1), algorithm = Proxgrad())
        predict(o, x)
    end
    context("ElasticNetPenalty") do
        o = SGModel(x, y, model = SVMLike(), penalty = ElasticNetPenalty(.1, .5), algorithm = Proxgrad())
        predict(o, x)
    end
end

end #module
