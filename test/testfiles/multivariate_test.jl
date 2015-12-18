module MultivariateTest

using TestSetup, OnlineStats, FactCheck

facts(@title "Multivariate") do
    context(@subtitle "KMeans") do
        x = vcat(randn(1000, 5), 10 + randn(1000, 5))
        o = KMeans(x, 2)
        o = KMeans(x, 2, 10)

        @fact nobs(o) --> 2000
        @fact size(o.value) --> (5, 2)
    end

end

end#module
