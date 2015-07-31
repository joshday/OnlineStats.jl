#--------------------------------------------------------# Type and Constructors
type Momentum{M <: SGModel, P <: Penalty} <: OnlineStat
    β::VecF                         # coefficients
    α::Float64                      # gradient updates are λ * g_{t+1} + α * g_t
    g::VecF                         # previous iteration's gradient
    η::Float64                      # constant part of learning rate
    model::M                        # <: SGModel
    penalty::P
    weighting::StochasticWeighting
    n::Int
end

function Momentum(p::Integer, wgt::StochasticWeighting = StochasticWeighting();
                  α::Float64 = 0.1,
                  η::Float64 = 1.0,
                  model::SGModel = L2Regression(),
                  penalty::Penalty = NoPenalty(),
                  start::VecF = zeros(p))
    Momentum(start, α, zeros(p), η, model, penalty, wgt, 0)
end

function Momentum(X::AMatF, y::AVecF, wgt::StochasticWeighting = StochasticWeighting(); kwargs...)
    o = Momentum(ncols(X), wgt; kwargs...)
    update!(o, X, y)
    o
end


#----------------------------------------------------------------------# update!
function update!(o::Momentum, x::AVecF, y::Float64)
    yhat = predict(o, x)
    ε = y - yhat

    λ = weight(o)
    @inbounds for j in 1:length(x)
        g = ∇f(o.model, ε, x[j], y, yhat) + ∇j(o.penalty, o.β, j)
        o.β[j] -= λ * o.η * g + o.α * o.g[j]
        o.g[j] = λ * g
    end

    o.n += 1
    nothing
end

function updatebatch!(o::Momentum, x::AMatF, y::AVecF)
    n, p = size(x)
    g = zeros(p)  # This will be the average gradient for all n new observations
    λ = weight(o)

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
        g[j] /= n
        o.β[j] -= λ * o.η * g[j] + o.α * o.g[j]
    end
    o.g = λ * g
    nothing
end


#------------------------------------------------------------------------# state
state(o::Momentum) = Any[copy(o.β), nobs(o)]
statenames(o::Momentum) = [:β, :nobs]

StatsBase.coef(o::Momentum) = o.β
StatsBase.predict(o::Momentum, x::AVecF) = predict(o.model, x, o.β)
StatsBase.predict(o::Momentum, X::AMatF) = predict(o.model, X, o.β)
