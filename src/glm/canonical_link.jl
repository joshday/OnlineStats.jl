# MM gradient algorithm for GLMs with canonical link
const _supported_dists = [
    Distributions.Normal,
    Distributions.Binomial,
    Distributions.Poisson
]

type GLM{D <: Distributions.UnivariateDistribution} <: OnlineStat
    β::VecF
    dist::D
    weighting::LearningRate
    n::Int
end

function GLM(p::Integer, wgt::LearningRate = LearningRate();
        family::Distributions.UnivariateDistribution = Distributions.Normal(),
        start = zeros(p)
    )
    typeof(family) in _supported_dists || error("$(typeof(family)) is not supported for GLM")
    GLM(start, family, wgt, 0)
end

function GLM(x::AMatF, y::AVecF, wgt::LearningRate = LearningRate(); kw...)
    o = GLM(size(x, 2), wgt; kw...)
    update!(o, x, y)
    o
end

#----------------------------------------------------------------------# update!
function update!(o::GLM, x::AVec, y::Float64)
end

function update!(o::GLM{Distributions.Poisson}, x::AVec, y::Float64, γ::Float64 = weight(o))
    ŷ = predict(o, x)
    u = γ * (y - ŷ)
    v =  1. / (sumabs(x) * ŷ)

    for j in 1:length(x)
        o.β[j] += sign(x[j]) * u * v
    end
    o.n += 1
end

function update!(o::GLM{Distributions.Normal}, x::AVec, y::Float64, γ::Float64 = weight(o))
    sumx = sumabs(x)
    ϵ = y - predict(o, x)
    for j in 1:length(x)
        o.β[j] += γ * sign(x[j]) * ϵ / sumx
    end
    o.n += 1
end

function updatebatch!(o::GLM, x::AMatF, y::AVecF)
    n = length(y)
    γ = weight(o) / n
    for i in 1:n
        update!(o, row(x, i), y[i], γ)
    end
end

#------------------------------------------------------------------------# state
statenames(o::GLM) = [:β, :nobs]
state(o::GLM) = Any[coef(o), nobs(o)]
StatsBase.coef(o::GLM) = copy(o.β)

StatsBase.predict(o::GLM, x::AMatF) = [predict(o,rowvec_view(x, i)) for i in 1:size(x, 1)]
StatsBase.predict(o::GLM{Distributions.Poisson}, x::AVecF) = exp(dot(x, coef(o)))
StatsBase.predict(o::GLM{Distributions.Normal}, x::AVecF) = dot(x, coef(o))





######################### TESTING
# srand(100)
# n, p = 1_000_000, 5
# x = randn(n, p)
# β = vcat(1.:p) / p
# # y = Float64[rand(Distributions.Poisson(exp(xb))) for xb in x*β]
# y = x * β + randn(n)
#
# o = OnlineStats.GLM(p, OnlineStats.LearningRate(r=.7), family = Distributions.Normal())
# @time OnlineStats.update!(o, x, y)
# show(o)
