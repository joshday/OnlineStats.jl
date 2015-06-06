module MeanTest

using OnlineStats
using DataFrames
using FactCheck

facts("Mean") do
    context("Mean") do
        # Mean, update!, merge, merge!, Base.mean
        n1, n2 = rand(1:1_000_000, 2)
        n = n1 + n2
        x1 = rand(n1)
        x2 = rand(n2)
        x = [x1, x2]

        o = Mean(x1)
        @fact o.μ => roughly(mean(x1))
        @fact o.n => n1

        update!(o, x2)
        @fact o.μ => roughly(mean(x))
        @fact o.n => n

        o1 = Mean(x1)
        o2 = Mean(x2)
        o3 = merge(o1, o2)
        merge!(o1, o2)
        @fact o1.n => o3.n
        @fact o1.μ => roughly(o3.μ)
        @fact mean(x)=> roughly(mean(o1))


        # empty constructor, state, Base.mean, nobs, Base.copy
        o = Mean()
        @fact o.μ => 0.0
        @fact o.n => 0
        @fact state(o) => Any[0.0, 0]
        @fact statenames(o) => [:μ, :nobs]
        @fact mean(o) => 0.0
        update!(o, x1)
        @fact mean(o) => roughly(mean(x1))
        @fact nobs(o) => n1
        o1 = copy(o)
        @fact mean(o) => roughly(mean(x1))
        @fact nobs(o) => n1
        o2 = Mean(x1[1])
        @fact mean(o2) => x1[1]
        @fact nobs(o2) => 1

        @fact OnlineStats.center(o, mean(o)) => 0.0
        @fact OnlineStats.uncenter(o, -mean(o)) => 0.0
        @fact OnlineStats.center!(o, mean(o)) => 0.0

        empty!(o)
        @fact mean(o) => 0.0
        @fact nobs(o) => 0
        @fact OnlineStats.weight(o, 1) => 1.
    end

    context("Means") do
        n = rand(1:1_000_000)
        p = rand(2:100)
        x1 = rand(n, p)
        o = Means(x1)
        @fact statenames(o) => [:μ, :nobs]
        @fact state(o) => Any[mean(o), nobs(o)]
        @fact mean(o) => roughly(vec(mean(x1, 1)))
    end

end # facts
end # module
