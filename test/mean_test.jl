module MeanTest

using OnlineStats
using DataFrames
using FactCheck


facts("*** Mean ***") do
    # Mean, update!, merge, merge!, Base.mean
    n1, n2 = rand(1:1_000_000, 2)
    n = n1 + n2
    x1 = rand(n1)
    x2 = rand(n2)
    x = [x1, x2]

    obj = Mean(x1)
    @fact obj.μ => roughly(mean(x1))
    @fact obj.n => n1

    update!(obj, x2)
    @fact obj.μ => roughly(mean(x))
    @fact obj.n => n

    obj1 = Mean(x1)
    obj2 = Mean(x2)
    obj3 = merge(obj1, obj2)
    merge!(obj1, obj2)
    @fact obj1.n => obj3.n
    @fact obj1.μ => roughly(obj3.μ)
    @fact mean(x)=> roughly(mean(obj1))


    # empty constructor, state, Base.mean, nobs, Base.copy
    obj = Mean()
    @fact obj.μ => 0.0
    @fact obj.n => 0
    # @fact state(obj, DataFrame) => DataFrame(variable = :μ, value = 0., nobs=0)
    @fact mean(obj) => 0.0
    update!(obj, x1)
    @fact mean(obj) => roughly(mean(x1))
    @fact nobs(obj) => n1
    obj1 = copy(obj)
    @fact mean(obj) => roughly(mean(x1))
    @fact nobs(obj) => n1
    obj2 = Mean(x1[1])
    @fact mean(obj2) => x1[1]
    @fact nobs(obj2) => 1

end # facts
end # module
