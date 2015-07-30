module VarianceTest

using OnlineStats, FactCheck


facts("Variance") do
    context("Variance") do
        o = Variance()
        o = Variance(rand(100))
        for i in 1:10
            n = rand(10:100)
            Variance(randn(n))
        end
        o = Variance(randn(1000))
        @fact nobs(o) --> 1000
        # @fact show(Variance()) --> show(Variance(0., 0., 0, EqualWeighting()))
        @fact Variance() --> Variance(0., 0., 0, EqualWeighting())

        n1, n2 = rand(1:1_000_000, 2)
        n = n1 + n2
        x1 = rand(n1)
        x2 = rand(n2)
        x = [x1; x2]

        @fact Variance(x1).μ --> roughly(mean(x1), .01)
        @fact Variance(x1).biasedvar --> roughly(var(x1 * (n1 - 1) / n1), .01)
        @fact Variance(x1).n --> n1
        @fact Variance(x1).weighting --> EqualWeighting()

        o = Variance(x1)
        @fact Variance(x1).μ --> roughly(mean(x1))
        @fact OnlineStats.name(o) --> "OVar"
        @fact o.μ --> roughly(mean(x1))
        @fact o.biasedvar --> roughly(var(x1) * ((n1 -1) / n1), 1e-5)
        @fact o.n --> n1

        update!(o, x2)
        @fact o.μ --> roughly(mean(x))
        @fact o.biasedvar --> roughly(var(x) * ((n -1) / n), 1e-5)
        @fact o.n --> n

        o1 = Variance(x1)
        o2 = Variance(x2)
        o3 = merge(o1, o2)
        merge!(o1, o2)
        @fact o1.n --> o3.n
        @fact o1.μ --> roughly(o3.μ)
        @fact o1.biasedvar --> roughly(o3.biasedvar)

        @fact mean(x) --> roughly(mean(o1))
        @fact var(x) --> roughly(var(o1), 1e-5)
        @fact update!(o1, x) --> nothing


        o = Variance()
        @fact o.μ --> 0.0
        @fact o.biasedvar --> 0.0
        @fact o.n --> 0
        @fact nobs(o) --> 0
        @fact mean(o) --> 0.0
        @fact var(o) --> 0.0
        @fact statenames(o) --> [:μ, :σ², :nobs]
        @fact state(o) --> Any[mean(o), var(o), nobs(o)]
        update!(o, x1)
        @fact mean(o) --> roughly(mean(x1))
        @fact var(o)  --> roughly(var(x1))
        @fact o.n --> n1
        o1 = copy(o)
        @fact mean(o1) --> roughly(mean(x1))
        @fact var(o1) --> roughly(var(x1))
        @fact o.n --> n1
        @fact nobs(o) --> n1

        x = rand()
        o = Variance(x)
        @fact mean(o) --> x
        @fact var(o) --> 0.
        @fact nobs(o) --> 1
        @fact std(o) --> 0.

        @fact OnlineStats.if0then1(0.) --> 1.
        @fact OnlineStats.if0then1(x) --> x
        update!(o, rand(100))
        @fact OnlineStats.standardize(o, x) --> (x - mean(o)) / std(o)
        @fact OnlineStats.unstandardize(o, x) --> x * std(o) + mean(o)
        OnlineStats.standardize!(o, 0.)
        @fact nobs(o) --> 102
        o = Variance()
        @fact OnlineStats.standardize!(o, 1.) --> 0.

        empty!(o)
        @fact mean(o) --> 0.
        @fact var(o) --> 0.

        o2 = Variance(rand(100))
        o = [o; o2]
        OnlineStats.DEBUG(typeof(o))

        x = rand(100)
        o = Variance()
        updatebatch!(o, x)
        @fact mean(o) --> mean(x)
        @fact var(o) --> roughly(var(x))
    end

    context("Variances") do
        o = Variances(5)
        o = Variances(rand(5))
        o = Variances(rand(10, 5))

        n = rand(1:1_000_000)
        p = rand(2:100)
        x1 = rand(n, p)
        o = Variances(x1)
        @fact statenames(o) --> [:μ, :σ², :nobs]
        @fact state(o) --> Any[mean(o), var(o), nobs(o)]
        @fact var(o) --> roughly(vec(var(x1, 1)), 1e-5)
        @fact mean(o) --> roughly(vec(mean(x1, 1)))
        @fact std(o) --> roughly(vec(std(x1, 1)), 1e-5)
        @fact typeof(Variances(rand(10,10))) --> Variances{EqualWeighting}
        @fact typeof(Variances(rand(1))) --> Variances{EqualWeighting}

        x = rand(10)
        o = Variances(x)
        @fact mean(o) --> x
        @fact var(o) --> zeros(10)
        @fact std(o) --> zeros(10)
        @fact OnlineStats.center(o, x) --> zeros(10)
        @fact OnlineStats.uncenter(o, -x) --> zeros(10)
        @fact OnlineStats.center!(o, x) --> zeros(10)
        @fact nobs(o) --> 2
        update!(o, rand(100, 10))
        @fact OnlineStats.standardize(o, x) --> roughly( (x - mean(o)) ./ std(o))
        @fact OnlineStats.unstandardize(o, x) --> roughly( x .* std(o) + mean(o))
        OnlineStats.standardize!(o, x)
        @fact nobs(o) --> 103

        empty!(o)
        @fact mean(o) --> zeros(10)
        @fact var(o) --> zeros(10)
        @fact nobs(o) --> 0

        x1 = rand(100, 4)
        x2 = rand(100, 4)
        x = vcat(x1, x2)

        o1 = Variances(x1)
        o2 = Variances(x2)
        o3 = merge(o1, o2)
        merge!(o1, o2)
        @fact mean(o1) --> mean(o3)
        @fact var(o1) --> var(o3)

        @fact nobs(o1) --> 200
        @fact mean(o1) --> roughly(vec(mean(vcat(x1, x2), 1)))
        @fact std(o1) --> roughly(vec(std(vcat(x1, x2), 1)), .01)

        x = rand(100, 5)
        o = Variances(5)
        updatebatch!(o, x)
        @fact mean(o) --> vec(mean(x, 1))
        @fact var(o) --> roughly(vec(var(x, 1)))
    end

end # facts
end # module
