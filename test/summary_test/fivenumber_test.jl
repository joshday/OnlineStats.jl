module FiveNumberTest
using OnlineStats, FactCheck, Distributions

facts("FiveNumberSummary") do
    x1 = rand(1_000_000)

    o = FiveNumberSummary(x1)

    @fact maximum(o) --> maximum(x1)
    @fact minimum(o) --> minimum(x1)
    @fact statenames(o) --> [:min, :q1, :median, :q3, :max, :nobs]
    @fact state(o) --> [o.extrema.min, o.quantiles.q[1], o.quantiles.q[2],
                              o.quantiles.q[3], o.extrema.max, nobs(o)]

    for i in 1:10000
        update!(o, rand(100))
    end

    @fact nobs(o) --> 2_000_000

     for i in 1:10000
        update!(o, rand(100))
    end

    @fact nobs(o) --> 3_000_000
end
end #module
