module SummaryTest

using OnlineStats
using FactCheck

facts("Summary") do
    Summary()
    Summary(0.)
    Summary(zeros(10))
    @fact mean(Summary()) => 0.
    @fact mean(Summary(0.)) => 0.

    n1 = rand(1:1_000_000, 1)[1]
    n2 = rand(1:1_000_000, 1)[1]
    x1 = rand(n1)
    x2 = rand(n2)
    x = vcat(x1, x2)


    o = Summary(x1)
    @fact o.var.μ => roughly(mean(x1))
    @fact o.var.biasedvar => roughly(var(x1) * (n1 - 1) / n1)
    @fact var(o) => roughly(var(x1), 1e-5)
    @fact o.extrema.max => maximum(x1)
    @fact o.extrema.min => minimum(x1)
    @fact o.n => n1

    @fact state(o) => [mean(o), var(o), maximum(o), minimum(o), nobs(o)]
    @fact statenames(o) => [:μ, :σ², :max, :min, :nobs]

    update!(o, x2)
    @fact o.var.μ => roughly(mean(x))
    @fact o.var.biasedvar => roughly(var(x) * (o.n - 1) / o.n, 1e-5)
    @fact o.extrema.max => maximum(x)
    @fact o.extrema.min => minimum(x)
    @fact o.n => n1 + n2

    o = Summary(x1)
    o2 = Summary(x2)
    o3 = merge(o, o2)
    @fact o3.var.μ => roughly(mean(x))
    @fact o3.var.biasedvar => roughly(var(x) * (o3.n - 1) / o3.n, 1e-5)
    @fact o3.extrema.max => maximum(x)
    @fact o3.extrema.min => minimum(x)

    merge!(o, o2)
    @fact o.var.μ => roughly(o3.var.μ)
    @fact o.var.biasedvar => roughly(o3.var.biasedvar, 1e-5)
    @fact o.extrema.max => o3.extrema.max
    @fact o.extrema.min => o3.extrema.min
    @fact o.n => o3.n

    @fact mean(o) => roughly(mean(x))
    @fact var(o) => roughly(var(x), 1e-5)
    @fact maximum(o) => maximum(x)
    @fact minimum(o) => minimum(x)
end

end # module
