

# First attempt at a generalized Adagrad framework.  
# TODO: I expect to be able to also combine Adagrad with Regularized Dual Averaging (RDA) as an alternative algorithm
# with better sparsity in resulting parameters for weakly convex regularization functions

# As a first pass we can limit loss and regularization functions to pre-defined ones that fix strict criteria.
# Any loss/reg function should be allowed to be swapped in, but we'll default to showing a big fat warning about
# how the results could be gibberish.


# Problem: argmin{βₜ} (Σ f(xₛ,yₛ,βₛ) + λ Ψ(βₜ))
# Online algorithm to solve for optimal estimate βₜ of parameter vector given some loss function f and
# regularization function Ψ, with all online estimates of βₛ, s <= t 

# TODO: add weighting?  might not be possible until we include RDA

# NOTE: if you want a bias term, add a 1 to your x input

# --------------------------------------------------------------------------

# placeholder loss/reg types and functions. 
# TODO: use EmpiricalRisks.jl or something else

# NOTE: I don't think I need the loss/reg values... only gradients

abstract LossFunction

# ε = y - Xβ
# f(ε) = ε²/2
# ∇f(ε) = df(ε)/dxᵢ = -ε * xᵢ
immutable SquareLoss <: LossFunction end
# f(::SquareLoss, y::Float64, ypred::Float64) = 0.5 * (y-ypred)^2
@inline ∇f(::SquareLoss, ε::Float64, xᵢ::Float64) = -ε * xᵢ

# note: this is equivalent to the negative of the logistic log likelihood
immutable LogisticLoss <: LossFunction end
# f(::LogisticLoss, y::Float64, ypred::Float64) = log(1 + exp(-y * ypred))
@inline ∇f(::LogisticLoss, ε::Float64, xᵢ::Float64) = -ε * xᵢ

# --------------------------------------------------------------------------

abstract RegularizationFunction

immutable NoReg <: RegularizationFunction end
# Ψ(reg::NoReg, β::VecF) = 0.0
@inline ∇Ψ(reg::NoReg, β::VecF, i::Int) = 0.0

# Ψ(β) = λ‖β‖₁
immutable L1Reg <: RegularizationFunction
  λ::Float64
end
# Ψ(reg::L1Reg, β::VecF) = reg.λ * sumabs(β)
@inline ∇Ψ(reg::L1Reg, β::VecF, i::Int) = reg.λ

# Ψ(β) = 0.5 λ‖β‖₂²
immutable L2Reg <: RegularizationFunction
  λ::Float64
end
# Ψ(reg::L2Reg, β::VecF) = 0.5 * reg.λ * sumabs2(β)
@inline ∇Ψ(reg::L2Reg, β::VecF, i::Int) = reg.λ * β[i]

# --------------------------------------------------------------------------

abstract LinkFunction

immutable IdentityLink <: LinkFunction end
link(::IdentityLink, xβ::Real) = xβ
invlink(::IdentityLink, y::Real) = y

immutable LogisticLink <: LinkFunction end
link(::LogisticLink, xβ::Real) = 1.0 / (1.0 + exp(-xβ))
invlink(::LogisticLink, y::Real) = log(y / (1.0 - y))

# --------------------------------------------------------------------------
# --------------------------------------------------------------------------


#-------------------------------------------------------# Type and Constructors
type Adagrad{LINK<:LinkFunction, LOSS<:LossFunction, REG<:RegularizationFunction} <: OnlineStat
  η::Float64  # learning rate
  β::VecF
  G::VecF  # Gₜᵢ  = Σ gₛᵢ²   (sum of squared gradients up to time t)
  link::LINK
  loss::LOSS
  reg::REG
  n::Int
end

function Adagrad(p::Int; 
                 η::Float64 = 0.1,
                 link::LinkFunction = IdentityLink(),
                 loss::LossFunction = SquareLoss(),
                 reg::RegularizationFunction = NoReg())
    Adagrad(η, zeros(p), zeros(p), link, loss, reg, 0)
end

function Adagrad(X::AMatF, y::AVecF; kwargs...)
    o = Adagrad(ncols(X); kwargs...)
    update!(o, X, y)
    o
end


#---------------------------------------------------------------------# update!


function update!(o::Adagrad, x::AVecF, y::Float64)
  ε = y - predict(o, x)

  @inbounds for i in eachindex(x)
    gᵢ = ∇f(o.loss, ε, x[i]) + ∇Ψ(o.reg, o.β, i)
    o.G[i] += gᵢ^2
    if o.G[i] != 0.0
      o.β[i] -= o.η * gᵢ / sqrt(o.G[i])
    end
  end

  o.n += 1
  nothing
end

function update!(o::Adagrad, X::AMatF, y::AVecF)
  for i in eachindex(y)
    update!(o, row(X,i), y[i])
  end
end


#-----------------------------------------------------------------------# state

state(o::Adagrad) = Any[copy(o.β), nobs(o)]
statenames(o::Adagrad) = [:β, :nobs]

StatsBase.coef(o::Adagrad) = o.β
StatsBase.predict(o::Adagrad, x::AVecF) = link(o.link, dot(x, o.β))
StatsBase.predict(o::Adagrad, X::AMatF) = link(o.link, X * o.β)

# --------------------------------------------------------------------------
