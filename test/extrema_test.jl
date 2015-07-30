module Extrema_test

using OnlineStats
using FactCheck

facts("Extrema") do
    o = Extrema()
    o = Extrema(1)
    o = Extrema(1.0)
    o = Extrema()
    @fact maximum(o) --> -Inf
    update!(o, 0.)
    @fact maximum(o) --> 0.

    # Extrema, update!, merge, merge!, max, min,
    n1, n2 = rand(1:1_000_000, 2)
    n = n1 + n2
    x1 = rand(n1)
    x2 = rand(n2)
    x = vcat(x1, x2)
    obj = Extrema(x1)
    @fact obj.max --> maximum(x1)
    @fact obj.min --> minimum(x1)
    @fact obj.n --> n1

    update!(obj, x2)
    @fact obj.max --> maximum(x)
    @fact obj.min --> minimum(x)
    @fact obj.n --> n

    obj1 = Extrema(x1)
    obj2 = Extrema(x2)
    obj3 = merge(obj1, obj2)
    merge!(obj1, obj2)
    @fact obj1.n --> obj3.n
    @fact obj1.max --> obj3.max
    @fact obj1.min --> obj3.min
    @fact maximum(x) --> obj3.max
    @fact minimum(x) --> obj3.min

    # Empty constructor, state, copy
    obj = Extrema()
    @fact maximum(obj) --> -Inf
    @fact minimum(obj) --> Inf
    @fact nobs(obj) --> 0

    update!(obj, x1)
    @fact maximum(obj) --> maximum(x1)
    @fact minimum(obj) --> minimum(x1)
    @fact nobs(obj) --> n1

    obj1 = copy(obj)
    @fact maximum(obj1) --> maximum(x1)
    @fact minimum(obj1) --> minimum(x1)
    @fact nobs(obj1) --> n1
    @fact statenames(obj) --> [:max, :min, :nobs]
    @fact state(obj) --> [maximum(obj), minimum(obj), nobs(obj)]
end

end  # module
