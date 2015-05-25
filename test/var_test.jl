module VarianceTest

using OnlineStats
using DataFrames
using FactCheck


facts("Variance") do
    context("Variance") do
        n1, n2 = rand(1:1_000_000, 2)
        n = n1 + n2
        x1 = rand(n1)
        x2 = rand(n2)
        x = [x1; x2]

        o = Variance(x1)
        @fact o.μ => roughly(mean(x1))
        @fact o.biasedvar => roughly(var(x1) * ((n1 -1) / n1), 1e-5)
        @fact o.n => n1

        update!(o, x2)
        @fact o.μ => roughly(mean(x))
        @fact o.biasedvar => roughly(var(x) * ((n -1) / n), 1e-5)
        @fact o.n => n

        o1 = Variance(x1)
        o2 = Variance(x2)
        o3 = merge(o1, o2)
        merge!(o1, o2)
        @fact o1.n => o3.n
        @fact o1.μ => roughly(o3.μ)
        @fact o1.biasedvar => roughly(o3.biasedvar)

        @fact mean(x) => roughly(mean(o1))
        @fact var(x) => roughly(var(o1), 1e-5) "might need special batch update for Variance?"


        o = Variance()
        @fact o.μ => 0.0
        @fact o.biasedvar => 0.0
        @fact o.n => 0
        @fact nobs(o) => 0
        @fact mean(o) => 0.0
        @fact var(o) => 0.0
        @fact statenames(o) => [:μ, :σ², :nobs]
        @fact state(o) => Any[mean(o), var(o), nobs(o)]
        update!(o, x1)
        @fact mean(o) => roughly(mean(x1))
        @fact var(o)  => roughly(var(x1))
        @fact o.n => n1
        o1 = copy(o)
        @fact mean(o1) => roughly(mean(x1))
        @fact var(o1) => roughly(var(x1))
        @fact o.n => n1
        @fact nobs(o) => n1
    end

    context("Variances") do
        n = rand(1:1_000_000)
        p = rand(2:100)
        x1 = rand(n, p)
        o = Variances(x1)
        @fact statenames(o) => [:μ, :σ², :nobs]
        @fact state(o) => Any[mean(o), var(o), nobs(o)]
        @fact var(o) => roughly(vec(var(x1, 1)), 1e-5)
        @fact mean(o) => roughly(vec(mean(x1, 1)))
        @fact std(o) => roughly(vec(std(x1, 1)), 1e-5)
    end

end # facts
end # module
