########################################################
module TestMyCode
using OnlineStats, Distributions, Plots
n, p = 1_000_000, 20
x = randn(n, p)

β = collect(1.:p) - p/2
y = x * β

# bernoulli responses
# β = (collect(1.:p) - p/2) / p
# y = [Float64(rand(Bernoulli(1 / (1 + exp(-xβi))))) for xβi in x*β]
# y = 2y - 1

# poisson responses
# β = (collect(1.:p) - p/2) / p
# y = [Float64(rand(Poisson(exp(xβi)))) for xβi in x*β]


β = vcat(0.0, β)

o = StochasticModel(x, y, model = L1Regression(), algorithm = RDA(), penalty = L1Penalty(.2))
@time o = StochasticModel(x, y, model = L1Regression(), algorithm = RDA(), penalty = L1Penalty(.2))

# o = SGModel(x,y, model = L1Regression(), algorithm = RDA())
# @time o = SGModel(x,y, model = L1Regression(), algorithm = RDA())

println(maxabs(coef(o) - β))
show(o)

# display(plot(o))
end # module
