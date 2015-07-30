

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

# old Loss/Link function stuff is commented out in the bottom of the file

# --------------------------------------------------------------------------


#-------------------------------------------------------# Type and Constructors
type Adagrad{M <: SGModel, P <: Penalty} <: OnlineStat
    β::VecF
    η::Float64  # learning rate
    G::VecF  # Gₜᵢ  = Σ gₛᵢ²   (sum of squared gradients up to time t)
    model::M
    penalty::P
    n::Int
end

function Adagrad(p::Int;
                 η::Float64 = 1.0,
                 model::SGModel = L2Regression(),
                 penalty::Penalty = NoPenalty(),
                 start::VecF = zeros(p))
    Adagrad(start, η, zeros(p), model, penalty, 0)
end

function Adagrad(X::AMatF, y::AVecF; kwargs...)
    o = Adagrad(ncols(X); kwargs...)
    update!(o, X, y)
    o
end


#---------------------------------------------------------------------# update!
function update!(o::Adagrad, x::AVecF, y::Float64)
    yhat = predict(o, x)
    ε = y - yhat

  @inbounds for j in 1:length(x)
    g = ∇f(o.model, ε, x[j], y, yhat) + ∇j(o.penalty, o.β, j)
    o.G[j] += g^2
    if o.G[j] != 0.0
      o.β[j] -= o.η * g / sqrt(o.G[j])
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


function updatebatch!(o::Adagrad, x::AMatF, y::AVecF)
    n, p = size(x)
    g = zeros(p)  # This will be the average gradient for all n new observations

    for i in 1:n  # for each observation, add the gradient
        xi = row(x, i)
        yi = y[i]
        yhat = predict(o, xi)
        ϵ = yi - yhat
        for j in 1:p  # for each dimension, add gradient
            g[j] += ∇f(o.model, ϵ, xi[j], yi, yhat) + ∇j(o.penalty, o.β, j)
        end
    end
    for j in 1:p
        o.G[j] += (g[j] / n) ^ 2  # divide by n to get average gradient
        if o.G[j] != 0.0
            o.β[j] -= o.η * g[j] / sqrt(o.G[j])
        end
    end
    nothing
end




#-----------------------------------------------------------------------# state

state(o::Adagrad) = Any[copy(o.β), nobs(o)]
statenames(o::Adagrad) = [:β, :nobs]

StatsBase.coef(o::Adagrad) = o.β
StatsBase.predict(o::Adagrad, x::AVecF) = predict(o.model, x, o.β)
StatsBase.predict(o::Adagrad, X::AMatF) = predict(o.model, X, o.β)


# --------------------------------------------------------------------------



# # OLD structure for Adagrad, SGD, etc.
# abstract LossFunction
#
# # ε = y - Xβ
# # f(ε) = ε²/2
# # ∇f(ε) = df(ε)/dxᵢ = -ε * xᵢ
# immutable SquareLoss <: LossFunction end
# # f(::SquareLoss, y::Float64, ypred::Float64) = 0.5 * (y-ypred)^2
# @inline ∇f(::SquareLoss, ε::Float64, xᵢ::Float64) = -ε * xᵢ
#
# # note: this is equivalent to the negative of the logistic log likelihood
# immutable LogisticLoss <: LossFunction end
# # f(::LogisticLoss, y::Float64, ypred::Float64) = log(1 + exp(-y * ypred))
# @inline ∇f(::LogisticLoss, ε::Float64, xᵢ::Float64) = -ε * xᵢ
#
# # Quantile Regression
# immutable QuantileLoss <: LossFunction
#     τ::Float64
#     function QuantileLoss(τ::Real = 0.5)
#         zero(τ) < τ < one(τ) || error("τ must be in (0, 1)")
#         new(@compat Float64(τ))
#     end
# end
# @inline ∇f(loss::QuantileLoss, ϵ::Float64, xᵢ::Float64) = (@compat Float64(ϵ < 0) - loss.τ) * xᵢ
#
#
# immutable AbsoluteLoss <: LossFunction end
# @inline ∇f(::AbsoluteLoss, ϵ::Float64, xᵢ::Float64) = (@compat Float64(ϵ < 0) - 0.5) * xᵢ
#
# # --------------------------------------------------------------------------
#
# abstract RegularizationFunction
#
# immutable NoReg <: RegularizationFunction end
# # Ψ(reg::NoReg, β::VecF) = 0.0
# @inline ∇Ψ(reg::NoReg, β::VecF, i::Int) = 0.0
#
# # Ψ(β) = λ‖β‖₁
# immutable L1Reg <: RegularizationFunction
#   λ::Float64
# end
# # Ψ(reg::L1Reg, β::VecF) = reg.λ * sumabs(β)
# @inline ∇Ψ(reg::L1Reg, β::VecF, i::Int) = reg.λ
#
# # Ψ(β) = 0.5 λ‖β‖₂²
# immutable L2Reg <: RegularizationFunction
#   λ::Float64
# end
# # Ψ(reg::L2Reg, β::VecF) = 0.5 * reg.λ * sumabs2(β)
# @inline ∇Ψ(reg::L2Reg, β::VecF, i::Int) = reg.λ * β[i]
#
# # --------------------------------------------------------------------------
#
# abstract LinkFunction
#
# immutable IdentityLink <: LinkFunction end
# @inline link(::IdentityLink, y::Real) = y
# @inline invlink(::IdentityLink, xβ::Real) = xβ
#
# immutable LogisticLink <: LinkFunction end
# @inline link(::LogisticLink, y::Real) = log(y / (1.0 - y))
# @inline invlink(::LogisticLink, xβ::Real) = 1.0 / (1.0 + exp(-xβ))
#
# # --------------------------------------------------------------------------
