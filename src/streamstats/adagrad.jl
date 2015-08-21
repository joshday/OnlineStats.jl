

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
type Adagrad{M <: SGModel, P <: Penalty} <: StochasticGradientStat
    β0::Float64
    β::VecF
    intercept::Bool
    η::Float64  # learning rate
    G0::Float64
    G::VecF  # Gₜᵢ  = Σ gₛᵢ²   (sum of squared gradients up to time t)
    model::M
    penalty::P
    n::Int
end

function Adagrad(p::Int;
                 intercept::Bool = true,
                 η::Float64 = 1.0,
                 model::SGModel = L2Regression(),
                 penalty::Penalty = NoPenalty(),
                 start::VecF = zeros(p + intercept))
    Adagrad(start[1] * intercept, start[1+intercept:end], intercept, η, 0.0, zeros(p), model, penalty, 0)
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

    if o.intercept
        g = ∇f(o.model, ε, 1.0, y, yhat)
        o.G0 += g^2
        if o.G0 != 0.0
            o.β0 -= o.η * g / sqrt(o.G0)
        end
    end

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
    g0 = 0.0

    for i in 1:n  # for each observation, add the gradient
        xi = row(x, i)
        yi = y[i]
        yhat = predict(o, xi)
        ϵ = yi - yhat
        g0 += ∇f(o.model, ϵ, 1.0, yi, yhat)
        for j in 1:p  # for each dimension, add gradient
            g[j] += ∇f(o.model, ϵ, xi[j], yi, yhat) + ∇j(o.penalty, o.β, j)
        end
    end

    if o.intercept
        o.G0 += (g0 / n) ^ 2
        if o.G0 != 0.0
            o.β0 -= o.η * g0 / sqrt(o.G0)
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
