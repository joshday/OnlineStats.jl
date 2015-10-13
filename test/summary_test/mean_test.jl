module MeanTest

using OnlineStats, FactCheck

facts("Mean") do
    context("Mean") do
        o = Mean()
        o = Mean(rand(10))
        for i in 1:10
            n = rand(100:1000)
            Mean(randn(n))
        end
        o = Mean(randn(10))
        @fact nobs(o) --> 10
        # @fact show(Mean()) --> show(Mean(0., 0, EqualWeighting()))
        @fact Mean() --> Mean(0., 0, EqualWeighting())

        # Mean, update!, merge, merge!, Base.mean
        n1, n2 = rand(1:1_000_000, 2)
        n = n1 + n2
        x1 = rand(n1)
        x2 = rand(n2)
        x = vcat(x1, x2)

        o = Mean(x1)
        @fact o.μ --> roughly(mean(x1))
        @fact o.n --> n1

        update!(o, x2)
        @fact o.μ --> roughly(mean(x))
        @fact o.n --> n

        o1 = Mean(x1)
        @fact Mean(x1).μ --> roughly(mean(x1))
        @fact Mean(x1).n --> n1
        @fact Mean(x1).weighting --> EqualWeighting()
        o2 = Mean(x2)
        o3 = merge(o1, o2)
        merge!(o1, o2)
        @fact o1.n --> o3.n
        @fact o1.μ --> roughly(o3.μ)
        @fact mean(x) --> roughly(mean(o1))
        @fact update!(o, x1) --> nothing


        # empty constructor, state, Base.mean, nobs, Base.copy
        o = Mean()
        @fact o.μ --> 0.0
        @fact o.n --> 0
        @fact state(o) --> Any[0.0, 0]
        @fact statenames(o) --> [:μ, :nobs]
        @fact mean(o) --> 0.0
        update!(o, x1)
        @fact mean(o) --> roughly(mean(x1))
        @fact nobs(o) --> n1
        o1 = copy(o)
        @fact mean(o) --> roughly(mean(x1))
        @fact nobs(o) --> n1
        o2 = Mean(collect(x1[1]))
        @fact mean(o2) --> x1[1]
        @fact nobs(o2) --> 1

        @fact OnlineStats.center(o, mean(o)) --> roughly(0.0, 1e-10)
        @fact OnlineStats.uncenter(o, -mean(o)) --> roughly(0.0, 1e-10)
        @fact OnlineStats.center!(o, mean(o)) --> roughly(0.0, 1e-10)

        empty!(o)
        @fact mean(o) --> 0.0
        @fact nobs(o) --> 0
        @fact OnlineStats.weight(o, 1) --> 1.

        o = Mean()
        x = rand(100)
        update!(o, x, b=50)
        @fact mean(o) --> roughly(mean(x))
        @fact nobs(o) --> 100
    end

    context("Means") do
        n = rand(1:100_000)
        p = rand(2:100)
        x1 = rand(n, p)
        o = Means(x1)
        @fact statenames(o) --> [:μ, :nobs]
        @fact state(o) --> Any[mean(o), nobs(o)]
        @fact mean(o) --> roughly(vec(mean(x1, 1)))

        x2 = rand(n, p)
        update!(o, x2, b = round(Int, n/ 2))
        @fact mean(o) --> roughly(vec(mean([x1; x2], 1)), 1e-3)

        x1 = rand(10)
        x2 = rand(10)
        o = Means(x1)
        @fact mean(o) --> x1

        @fact OnlineStats.center(o, x1) --> zeros(10)
        @fact OnlineStats.center!(o, x2) --> x2 - vec(mean([x1 x2], 2))
        @fact OnlineStats.uncenter(o, -mean(o)) --> roughly(zeros(10))

        empty!(o)
        @fact mean(o) --> zeros(10)
        @fact nobs(o) --> 0

        o1 = Means(x1)
        o2 = Means(x2)
        o3 = merge!(o1, o2)
        update!(o1, x2)
        @fact mean(o1) --> mean(o3)
        @fact nobs(o1) --> nobs(o3)

        o = Means(5, LearningRate(r = .7))
        o = Means(zeros(5), 5, 0, LearningRate(r = .7))
    end

end # facts
end # module
