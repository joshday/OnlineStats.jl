module SummaryTest

using OnlineStats
using FactCheck

facts("Summary") do
    Summary()
    Summary(0.)
    Summary(zeros(10))
    @fact mean(Summary()) --> 0.
    @fact mean(Summary(0.)) --> 0.

    n1 = rand(1:1_000_000, 1)[1]
    n2 = rand(1:1_000_000, 1)[1]
    x1 = rand(n1)
    x2 = rand(n2)
    x = vcat(x1, x2)

    o = Summary(x1)
    @fact o.var.μ --> roughly(mean(x1))
    @fact o.var.biasedvar --> roughly(var(x1) * (n1 - 1) / n1)
    @fact var(o) --> roughly(var(x1), 1e-5)
    @fact std(o) --> roughly(std(x1), 1e-3)
    @fact o.extrema.max --> maximum(x1)
    @fact o.extrema.min --> minimum(x1)
    @fact o.n --> n1

    @fact state(o) --> [mean(o), var(o), maximum(o), minimum(o), nobs(o)]
    @fact statenames(o) --> [:μ, :σ², :max, :min, :nobs]

    update!(o, x2)
    @fact o.var.μ --> roughly(mean(x))
    @fact o.var.biasedvar --> roughly(var(x) * (o.n - 1) / o.n, 1e-5)
    @fact o.extrema.max --> maximum(x)
    @fact o.extrema.min --> minimum(x)
    @fact o.n --> n1 + n2

    o = Summary(x1)
    o2 = Summary(x2)
    o3 = merge(o, o2)
    @fact o3.var.μ --> roughly(mean(x))
    @fact o3.var.biasedvar --> roughly(var(x) * (o3.n - 1) / o3.n, 1e-5)
    @fact o3.extrema.max --> maximum(x)
    @fact o3.extrema.min --> minimum(x)

    merge!(o, o2)
    @fact o.var.μ --> roughly(o3.var.μ)
    @fact o.var.biasedvar --> roughly(o3.var.biasedvar, 1e-5)
    @fact o.extrema.max --> o3.extrema.max
    @fact o.extrema.min --> o3.extrema.min
    @fact o.n --> o3.n

    @fact mean(o) --> roughly(mean(x))
    @fact var(o) --> roughly(var(x), 1e-5)
    @fact maximum(o) --> maximum(x)
    @fact minimum(o) --> minimum(x)
end

facts("Diff") do
    o = Diff()
    @fact diff(o) --> 0.0
    @fact state(o) --> Any[0.0, 0.0, 0]
    @fact statenames(o) --> [:diff, :last, :nobs]

    @fact update!(o, 10) --> nothing
    @fact typeof(last(o)) --> Float64
    @fact last(o) --> 10.0
    @fact diff(o) --> 0.0

    @fact update!(o, convert(Float32, 11.0)) --> nothing
    @fact last(o) --> 11.0
    @fact diff(o) --> 1.0

    o = Diff(1)
    @fact typeof(last(o)) --> Int
    @fact diff(o) --> 0
    @fact last(o) --> 1
    @fact nobs(o) --> 1
    @fact update!(o, 0.1:0.2:0.9) --> nothing
    @fact diff(o) --> 0
    @fact last(o) --> 1
    @fact nobs(o) --> 6
    @fact update!(o, 0.1:0.5:2.7) --> nothing
    @fact diff(o) --> 1
    @fact last(o) --> 3
    @fact nobs(o) --> 12

    o = Diff(rand(10))
end

facts("Diffs") do
    p = 2
    o = Diffs(p)
    @fact diff(o) --> zeros(p)
    @fact state(o) --> Any[zeros(p), zeros(p), 0]
    @fact statenames(o) --> [:diff, :last, :nobs]

    @fact update!(o, 10:11.) --> nothing
    @fact typeof(last(o)) --> Vector{Float64}
    @fact typeof(diff(o)) --> Vector{Float64}
    @fact last(o) --> Float64[10.0, 11.0]
    @fact diff(o) --> zeros(p)

    @fact update!(o, 11:2:13.1) --> nothing
    @fact last(o) --> roughly(Float64[11.0, 13.0])
    @fact diff(o) --> roughly(Float64[1.0, 2.0])

    o = Diffs(ones(Int,p))
    @fact typeof(last(o)) --> Vector{Int}
    @fact typeof(diff(o)) --> Vector{Int}
    @fact diff(o) --> Int[0,0]
    @fact last(o) --> Int[1,1]
    @fact nobs(o) --> 1
    @fact update!(o, Int[10,20]) --> nothing
    @fact diff(o) --> Int[9,19]
    @fact last(o) --> Int[10,20]
    @fact nobs(o) --> 2
    @fact update!(o, vcat(2*ones(Int,p)', 5*ones(Int,p)')) --> nothing
    @fact diff(o) --> Int[3,3]
    @fact last(o) --> Int[5,5]
    @fact nobs(o) --> 4

    o = Diffs(randn(100,10))
    empty!(o)
end


end # module
