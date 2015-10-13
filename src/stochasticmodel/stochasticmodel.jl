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
immutable L1Loss <: Loss end
immutable L2Loss <: Loss end


@inline ∇ᵢloss(::L1Loss, ϵᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -sign(ϵᵢ)
@inline ∇ᵢloss(::L2Loss, ϵᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -ϵᵢ

#-------------------------------------------------------------------------# Link
immutable IdentityLink <: Link end
@inline predict(::IdentityLink, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline predict(::IdentityLink, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline ∇ᵢlink(::IdentityLink, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = xᵢ

type StochasticModel{A<:Algorithm, Li<:Link, Lo<:Loss, P<:Penalty} <: OnlineStat
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
alg(o::StochasticModel) = o.algorithm
pen(o::StochasticModel) = o.penalty


function update!(o::StochasticModel, x::AMatF, y::AVecF)
    for i in 1:length(y)
        update!(o, rowvec_view(x,i), y[i])
    end
end

function update!(o::StochasticModel, x::AVecF, y::Float64)
    o.n += 1
    updateβ!(o, x, y)
end
