# Online MM gradient algorithm for OnlineGLMs with canonical link
const _supported_dists = [
    Distributions.Normal,
    Distributions.Binomial,
    Distributions.Poisson
]

type OnlineGLM{D <: Distributions.UnivariateDistribution} <: OnlineStat
    β::VecF
    dist::D
    weighting::LearningRate
    n::Int
end

function OnlineGLM(p::Integer, wgt::LearningRate = LearningRate();
        family::Distributions.UnivariateDistribution = Distributions.Normal(),
        start = zeros(p)
    )
    typeof(family) in _supported_dists || error("$(typeof(family)) is not supported for OnlineGLM")
    OnlineGLM(start, family, wgt, 0)
end

function OnlineGLM(x::AMatF, y::AVecF, wgt::LearningRate = LearningRate(); kw...)
    o = OnlineGLM(size(x, 2), wgt; kw...)
    update!(o, x, y)
    o
end

#----------------------------------------------------------------------# update!
function update!(o::OnlineGLM, x::AVec, y::Float64, γ::Float64 = weight(o))
    ŷ = predict(o, x)
    for j in 1:length(x)
        o.β[j] += x[j] * _grad(o.dist, γ, x, y, ŷ)
    end
    o.n += 1
end

@inline function _grad(::Distributions.Binomial, γ::Float64, x::AVecF, y::Float64, ŷ::Float64)
     γ * (y - ŷ) / (sumabs2(x) * ŷ * (1 - ŷ))
end

@inline function _grad(::Distributions.Poisson, γ::Float64, x::AVecF, y::Float64, ŷ::Float64)
     γ * (y - ŷ) / (sumabs2(x) * ŷ)
end

@inline function _grad(::Distributions.Normal, γ::Float64, x::AVecF, y::Float64, ŷ::Float64)
     γ * (y - ŷ) / sumabs2(x)
end

#------------------------------------------------------------------------# state
statenames(o::OnlineGLM) = [:β, :nobs]
state(o::OnlineGLM) = Any[coef(o), nobs(o)]
StatsBase.coef(o::OnlineGLM) = copy(o.β)

StatsBase.predict(o::OnlineGLM, x::AMatF) = [predict(o,rowvec_view(x, i)) for i in 1:size(x, 1)]
StatsBase.predict(o::OnlineGLM{Distributions.Poisson}, x::AVecF) = exp(dot(x, o.β))
StatsBase.predict(o::OnlineGLM{Distributions.Normal}, x::AVecF) = dot(x, o.β)
StatsBase.predict(o::OnlineGLM{Distributions.Binomial}, x::AVecF) = 1.0 / (1.0 + exp(-dot(x, o.β)))





######################### TESTING
if true
    n, p = 1_000_000, 10
    x = randn(n, p)
    β = vcat(1.:p) / p

    # POISSON
    # y = Float64[rand(Distributions.Poisson(exp(xb))) for xb in x*β]
    # o = OnlineStats.OnlineGLM(x, y, OnlineStats.LearningRate(r=.8), family = Distributions.Poisson())
    # @time o = OnlineStats.OnlineGLM(x, y, OnlineStats.LearningRate(r=.8), family = Distributions.Poisson())
    # o2 = OnlineStats.StochasticModel(x,y,model = OnlineStats.PoissonRegression(), algorithm = OnlineStats.SGD(r=.7), intercept = false)
    # o2 = OnlineStats.StochasticModel(x,y,model = OnlineStats.PoissonRegression(), algorithm = OnlineStats.SGD(r=.7), intercept = false)
    # o3 = OnlineStats.StochasticModel(x,y,model = OnlineStats.PoissonRegression(), algorithm = OnlineStats.ProxGrad(), intercept = false)
    # o4 = OnlineStats.StochasticModel(x,y,model = OnlineStats.PoissonRegression(), algorithm = OnlineStats.RDA(), intercept = false)
    # o5 = OnlineStats.StochasticModel(x,y,model = OnlineStats.PoissonRegression(), algorithm = OnlineStats.SAG(), intercept = false)

    # BINOMIAL
    # y = Float64[rand(Distributions.Bernoulli(1 / (1 + exp(-xb)))) for xb in x*β]
    # @time o = OnlineStats.OnlineGLM(x, y, OnlineStats.LearningRate(λ = .5), family = Distributions.Binomial())
    # o2 = OnlineStats.StochasticModel(x,y,model = OnlineStats.LogisticRegression(),
    #     algorithm = OnlineStats.SGD(r=.5), intercept = false)
    # o3 = OnlineStats.StochasticModel(x,y,model = OnlineStats.LogisticRegression(),
    #     algorithm = OnlineStats.ProxGrad(), intercept = false)
    # o4 = OnlineStats.StochasticModel(x,y,model = OnlineStats.LogisticRegression(),
    #     algorithm = OnlineStats.RDA(), intercept = false)
    # o5 = OnlineStats.StochasticModel(x,y,model = OnlineStats.LogisticRegression(),
    #     algorithm = OnlineStats.SAG(), intercept = false)

    # NORMAL
    y = x * β + randn(n)
    @time o = OnlineStats.OnlineGLM(x, y, OnlineStats.LearningRate(r=.7))
    o2 = OnlineStats.StochasticModel(x, y, algorithm = OnlineStats.SGD(), intercept = false)
    o3 = OnlineStats.StochasticModel(x, y, algorithm = OnlineStats.ProxGrad(), intercept = false)
    o4 = OnlineStats.StochasticModel(x, y, algorithm = OnlineStats.RDA(), intercept = false)
    o5 = OnlineStats.StochasticModel(x, y, algorithm = OnlineStats.SAG(), intercept = false)

    println("\n\n")
    println("maxabs(β - coef(o)) for")
    println()
    println("glm:      ", maxabs(β - coef(o)))
    println("sgd:      ", maxabs(β - coef(o2)))
    println("proxgrad: ", maxabs(β - coef(o3)))
    println("rda:      ", maxabs(β - coef(o4)))
    println("sag:      ", maxabs(β - coef(o5)))
end #if
