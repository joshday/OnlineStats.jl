module ModelDef

using ArrayViews

export
    Loss, L2Loss,
    Link, IdentityLink,
    Penalty, NoPenalty,
    ModelDefinition, L2Regression,
    StochasticModel,
    predict

#------------------------------------------------------------------------# types
typealias VecF Vector{Float64}
typealias MatF Matrix{Float64}
typealias AVec{T} AbstractVector{T}
typealias AMat{T} AbstractMatrix{T}
typealias AVecF AVec{Float64}
typealias AMatF AMat{Float64}

abstract Loss
abstract Link
abstract Penalty
abstract Algorithm

#-------------------------------------------------------------------------# Loss
immutable L2Loss <: Loss end
@inline ∇ᵢloss(::L2Loss, ϵᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -ϵᵢ

#-------------------------------------------------------------------------# Link
immutable IdentityLink <: Link end
@inline predict(::IdentityLink, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline predict(::IdentityLink, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline ∇ᵢlink(::IdentityLink, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = xᵢ


#----------------------------------------------------------------------# Penalty
immutable NoPenalty <: Penalty end
@inline ∇j(::NoPenalty, β) = 0.0

#--------------------------------------------------------------------# Algorithm
immutable SGD <: Algorithm   # step size is γ = η * nobs ^ -r
    η::Float64
    r::Float64
    function SGD(;η::Real = 1.0, r::Real = .5)
        @assert η > 0
        @assert 0 < r <= 1
        new(Float64(η), Float64(r))
    end
end

# Shortcut Definition
L2Regression(p::Penalty) = ModelDefinition(L2Loss(), IdentityLink(), p)

type StochasticModel{A<:Algorithm, Li<:Link, Lo<:Loss, P<:Penalty}
    β0::Float64
    β::VecF
    intercept::Bool
    link::Li
    loss::Lo
    penalty::P
    algorithm::A
    n::Int
end

function StochasticModel(
        p::Int;
        intercept::Bool = true,
        link::Link = IdentityLink(),
        loss::Loss = L2Loss(),
        penalty::Penalty = NoPenalty(),
        algorithm::Algorithm = SGD()
    )
    StochasticModel(0.0, zeros(p), intercept, link, loss, penalty, algorithm, 0)
end

function StochasticModel(x::AMatF, y::AVecF; keyargs...)
    o = StochasticModel(size(x, 2); keyargs...)
    update!(o, x, y)
    o
end

@inline predict(o::StochasticModel, x::AVecF) = predict(o.link, x, o.β, o.β0)

function update!(o::StochasticModel, x::AMatF, y::AVecF)
    for i in 1:length(y)
        update!(o, rowvec_view(x,i), y[i])
    end
end

function update!(o::StochasticModel, x::AVecF, y::Float64)
    o.n += 1
    updateβ!(o, x, y)
end

alg(o::StochasticModel) = o.algorithm
nobs(o::StochasticModel) = o.n

function updateβ!(o::StochasticModel{SGD}, x::AVecF, y::Float64)
    yhat = predict(o, x)
    ϵ = y - yhat
    l = ∇ᵢloss(o.loss, ϵ, y, yhat)

    γ = alg(o).η / nobs(o) ^ alg(o).r

    if o.intercept
        o.β0 -= γ * l * ∇ᵢlink(o.link, ϵ, 1.0, y, yhat)
    end

    @inbounds for j in 1:length(x)
        g = l * ∇ᵢlink(o.link, ϵ, x[j], y, yhat)
        o.β[j] -= γ * add∇j(g, o.penalty, o.β, j)
    end
    nothing
end

@inline add∇j(x::Float64, ::NoPenalty, β::VecF, i::Int) = x

end #module




########################################################
module TestMyCode
using ModelDef
import OnlineStats
n,p = 1_000_000, 20
x = randn(n, p)
β = collect(1.:p)
y = x*β + randn(n)

# run once to compile
o = StochasticModel(x, y)
o2 = OnlineStats.SGModel(x, y)

# get times
@time o = StochasticModel(x, y)
@time o2 = OnlineStats.SGModel(x, y)

println(maxabs(o.β - o2.β))
end # module
