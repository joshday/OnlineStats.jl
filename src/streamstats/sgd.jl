#--------------------------------------------------------# Type and Constructors
type SGD{M <: SGModel, P <: Penalty} <: StochasticGradientStat
    β0::Float64                     # intercept
    β::VecF                         # coefficients
    intercept::Bool                 # intercept in model?
    η::Float64                      # constant part of learning rate
    model::M                        # <: SGModel
    penalty::P                      # <: Penalty
    weighting::StochasticWeighting  # weighting scheme
    n::Int                          # number of observations
end

function SGD(p::Integer, wgt::StochasticWeighting = StochasticWeighting();
             intercept::Bool = true,
             η::Float64 = 1.0,
             model::SGModel = L2Regression(),
             penalty::Penalty = NoPenalty(),
             start::VecF = zeros(p + intercept))
    SGD(start[1] * intercept, start[1 + intercept:end], intercept, η, model, penalty, wgt, 0)
end

function SGD(X::AMatF, y::AVecF, wgt::StochasticWeighting = StochasticWeighting(); kwargs...)
    o = SGD(ncols(X), wgt; kwargs...)
    update!(o, X, y)
    o
end


#----------------------------------------------------------------------# update!
function update!(o::SGD, x::AVecF, y::Float64)
    yhat = predict(o, x)
    ε = y - yhat

    λ = weight(o) * o.η

    #intercept
    if o.intercept
        o.β0 -= λ * ∇f(o.model, ε, 1.0, y, yhat)
    end

    #everything else
    @inbounds for j in 1:length(x)
        g = ∇f(o.model, ε, x[j], y, yhat) + ∇j(o.penalty, o.β, j)
        o.β[j] -= λ * g
    end

    o.n += 1
    nothing
end


function updatebatch!(o::SGD, x::AMatF, y::AVecF)
    n, p = size(x)
    g0 = 0.0      # average gradient for intercept
    g = zeros(p)  # This will be the average gradient for all n new observations
    λ = weight(o) * o.η

    for i in 1:n  # for each observation, add the gradient
        xi = row(x, i)
        yi = y[i]
        yhat = predict(o, xi)
        ϵ = yi - yhat

        #intercept
        if o.intercept
            g0 += λ * ∇f(o.model, ϵ, 1.0, yi, yhat)
        end

        # everything else
        for j in 1:p
            g[j] += ∇f(o.model, ϵ, xi[j], yi, yhat) + ∇j(o.penalty, o.β, j)
        end
    end

    # update coefficients
    o.β0 -= λ * g0 / n
    for j in 1:p
        o.β[j] -= λ * g[j] / n
    end
    nothing
end

#------------------------------------------------------------------------# state
# state(o::SGD) = Any[coef(o), nobs(o)]
# statenames(o::SGD) = [:β, :nobs]
#
# StatsBase.coef(o::SGD) = vcat(o.β0, o.β)
# StatsBase.predict(o::SGD, x::AVecF) = predict(o.model, x, o.β, o.β0)
# StatsBase.predict(o::SGD, X::AMatF) = predict(o.model, X, o.β, o.β0)





# # generalized SGD framework
#
# # Link and Loss functions are defined in adagrad.jl
#
# #--------------------------------------------------------# Type and Constructors
# """
# `SGD(x, y, wgt; link, loss, reg, start)`
#
# Generic type for stochastic gradient descent algorithms.
#
# Keyword arguments are:
#
# - `link`: link function (`IdentityLink()`, `LogisticLink()`)
# - `loss`: loss function (`SquareLoss()`, `LogisticLoss()`, `QuantileLoss(τ)`)
# - `reg`: regularizer/penalty (`NoReg`, `L1Reg`, `L2Reg`)
# - `start`: starting value (defaults to zeros)
# """
# type SGD{LINK<:LinkFunction, LOSS<:LossFunction, REG<:RegularizationFunction} <: OnlineStat
#     β::VecF
#     η::Float64  # Constant step size
#     link::LINK
#     loss::LOSS
#     reg::REG
#     weighting::StochasticWeighting
#     n::Int
# end
#
# function SGD(p::Integer, wgt::StochasticWeighting = StochasticWeighting();
#              η::Float64 = 1.0,
#              link::LinkFunction = IdentityLink(),
#              loss::LossFunction = SquareLoss(),
#              reg::RegularizationFunction = NoReg(),
#              start::VecF = zeros(p))
#     SGD(start, η, link, loss, reg, wgt, 0)
# end
#
# function SGD(X::AMatF, y::AVecF, wgt::StochasticWeighting = StochasticWeighting(); kwargs...)
#     o = SGD(ncols(X), wgt; kwargs...)
#     update!(o, X, y)
#     o
# end
#
#
# #---------------------------------------------------------------------# update!
# function update!(o::SGD, x::AVecF, y::Float64)
#     ε = y - predict(o, x)
#
#     λ = weight(o) * o.η
#     for j in 1:length(x)
#         g = ∇f(o.loss, ε, x[j]) + ∇Ψ(o.reg, o.β, j)
#         o.β[j] -= λ * g
#     end
#
#     o.n += 1
#     nothing
# end
#
#
# @inline function _update_average_gradient!(o::SGD, x::AVecF, y::Float64, w::Float64)
#     ε = y - predict(o, x)
#     n2inv = @compat Float64(1 / length(x))
#     for j in 1:length(x)
#         g = ∇f(o.loss, ε, x[j]) + ∇Ψ(o.reg, o.β, j)
#         o.β[j] -= w * g * n2inv
#     end
#     o.n += 1
#     nothing
# end
#
# function updatebatch!(o::SGD, x::AMatF, y::AVecF)
#     n2 = length(y)
#     λ = weight(o) * o.η
#
#     for i in 1:n2
#         _update_average_gradient!(o, row(x, i), y[i], λ)
#     end
# end
#
#
# # Special update for linear regression lasso
# # If something gets set to zero it stays zero forever...this is the only way I've
# # been able to generate a sparse solution
# positive_or_zero(x::Float64) = x > 0 ? x : 0.0
# function update!(o::SGD{IdentityLink, SquareLoss, L1Reg}, x::AVecF, y::Float64)
#     ϵ = y - predict(o, x)
#     γ = weight(o) * o.η
#     for j in 1:length(x)
#         βval = o.β[j]
#         if nobs(o) > 10 && βval == 0
#             o.β[j] = 0.0
#         else
#             u = abs(βval) * (sign(βval) .!= -1)  # positive or zero
#             v = abs(βval) * (sign(βval) .== -1)  # negative
#             u = positive_or_zero(u - γ * (o.reg.λ - ϵ * x[j]))
#             v = positive_or_zero(v - γ * (o.reg.λ + ϵ * x[j]))
#             o.β[j] = u - v
#         end
#     end
#     o.n += 1
#     nothing
# end
#
# #-----------------------------------------------------------------------# state
#
# state(o::SGD) = Any[copy(o.β), nobs(o)]
# statenames(o::SGD) = [:β, :nobs]
#
# StatsBase.coef(o::SGD) = o.β
# StatsBase.predict(o::SGD, x::AVecF) = invlink(o.link, dot(x, o.β))
# StatsBase.predict(o::SGD, X::AMatF) = invlink(o.link, X * o.β)
