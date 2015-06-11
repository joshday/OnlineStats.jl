module LogReg_test

using OnlineStats, FactCheck, StatsBase

logitinverse(x) = 1. / (1 + exp(-x))
@vectorize_1arg Number logitinverse

facts("LogReg") do
    context("LogRegSGD") do
        @fact OnlineStats.inverselogit(.5) => 1 / (1 + exp(-.5))
        o = LogRegSGD(5)

        β = [1:5]
        x = randn(100, 5)
        y = int(logitinverse(x*β) .< rand(100))

        updatebatch!(o, x, y)
        o = LogRegSGD(x, y)
        updatebatch!(o, x, y)

        @fact statenames(o) => [:β, :nobs]
        @fact state(o)[1] => coef(o)
        @fact state(o)[2] => nobs(o)

        @fact predict(o, x) => logitinverse(x*coef(o))
    end

    context("LogRegSGD2") do
        @fact OnlineStats.inverselogit(.5) => 1 / (1 + exp(-.5))
        o = LogRegSGD2(5)

        β = [1:5]
        x = randn(100, 5)
        y = int(logitinverse(x*β) .< rand(100))

        updatebatch!(o, x, y)
        o = LogRegSGD2(x, y)
        updatebatch!(o, x, y)

        @fact statenames(o) => [:β, :nobs]
        @fact state(o)[1] => coef(o)
        @fact state(o)[2] => nobs(o)

        @fact predict(o, x) => logitinverse(x*coef(o))
    end

    context("LogRegMM") do
        @fact OnlineStats.inverselogit(.5) => 1 / (1 + exp(-.5))
        o = LogRegMM(5)

        β = [1:5]
        x = randn(100, 5)
        y = int(logitinverse(x*β) .< rand(100))

        updatebatch!(o, x, y)
        o = LogRegMM(x, y)
        update!(o, x, y)

        @fact statenames(o) => [:β, :nobs]
        @fact state(o)[1] => coef(o)
        @fact state(o)[2] => nobs(o)

        @fact predict(o, x) => logitinverse(x*coef(o))
    end
end
end  # module
