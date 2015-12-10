module StatLearnTest

using TestSetup, OnlineStats, Distributions, FactCheck
import OnlineStats: _j

facts(@title "StatLearn") do
    n, p = 1_000, 10
    x = randn(n, p)
    β = collect(linspace(-1,1,p))

    context(@subtitle "L2Regression") do
        y = x*β + randn(n)
        StatLearn(x, y)
    end

    context(@subtitle "L1Regression") do
        y = x*β + randn(n)
        StatLearn(x, y, model = L1Regression())
    end

    context(@subtitle "LogisticRegression") do
        y = [rand(Bernoulli(1.0 / (1.0 + exp(-η)))) for η in x*β]
        StatLearn(x, y, model = LogisticRegression())
    end
end

end #module
