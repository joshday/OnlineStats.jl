module FitMethodsTest

using TestSetup, OnlineStats, FactCheck
srand(02082016)  # today's date...removes nondeterministic NormalMix algorithm divergence.

facts(@title "fit! methods") do
    context(@subtitle "Single Observation") do
        o = Mean()
        fit!(o, randn())
        fit!(o, randn(), rand())
        @fact nobs(o) --> 2

        o = Means(2)
        fit!(o, randn(2))
        fit!(o, randn(2), rand())
        @fact nobs(o) --> 2

        o = LinReg(2)
        fit!(o, randn(2), randn())
        fit!(o, randn(2), randn(), rand())
        @fact nobs(o) --> 2
    end
    context(@subtitle "Multiple Observations") do
        o = Mean()
        fit!(o, randn(100))
        fit!(o, randn(100), rand(100))
        fit!(o, randn(100), .1)
        @fact nobs(o) --> 300

        o = Means(2)
        fit!(o, randn(100, 2))
        fit!(o, randn(100, 2), rand(100))
        fit!(o, randn(100, 2), .1)
        @fact nobs(o) --> 300

        o = LinReg(2)
        fit!(o, randn(100, 2), randn(100))
        fit!(o, randn(100, 2), randn(100), rand(100))
        fit!(o, randn(100, 2), randn(100), .1)
        @fact nobs(o) --> 300
    end
end  # facts

end  # module
