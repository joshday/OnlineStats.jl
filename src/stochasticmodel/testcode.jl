########################################################
module TestMyCode
using OnlineStats, Distributions
n, p = 1_000_000, 20
x = randn(n, p)

β = collect(1.:p)
y = x * β

# bernoulli responses
# β = (collect(1.:p) - p/2) / p
# y = [Float64(rand(Bernoulli(1 / (1 + exp(-xβi))))) for xβi in x*β]
# y = 2y - 1

# poisson responses
# β = (collect(1.:p) - p/2) / p
# y = [Float64(rand(Poisson(exp(xβi)))) for xβi in x*β]


β = vcat(0.0, β)

# run once to compile
o = StochasticModel(x, y, model = L1Regression(), algorithm = RDA())

# get time
@time o = StochasticModel(x, y, model = L1Regression(), algorithm = RDA())

# o = SGModel(x,y, model = HuberRegression(2.))
# @time o = SGModel(x,y, model = HuberRegression(2.))

println(maxabs(coef(o) - β))
end # module
