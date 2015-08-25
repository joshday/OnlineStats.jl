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

    γ = weight(o) * o.η

    #intercept
    if o.intercept
        o.β0 -= γ * ∇f(o.model, ε, 1.0, y, yhat)
    end

    #everything else
    @inbounds for j in 1:length(x)
        g = ∇f(o.model, ε, x[j], y, yhat) + ∇j(o.penalty, o.β, j)
        o.β[j] -= γ * g
    end

    o.n += 1
    nothing
end


function updatebatch!(o::SGD, x::AMatF, y::AVecF)
    n, p = size(x)
    g0 = 0.0      # average gradient for intercept
    g = zeros(p)  # This will be the average gradient for all n new observations
    γ = weight(o) * o.η

    @inbounds for i in 1:n  # for each observation, add the gradient
        xi = row(x, i)
        yi = y[i]
        yhat = predict(o, xi)
        ϵ = yi - yhat

        #intercept
        if o.intercept
            g0 += γ * ∇f(o.model, ϵ, 1.0, yi, yhat)
        end

        # everything else
        @inbounds for j in 1:p
            g[j] += ∇f(o.model, ϵ, xi[j], yi, yhat) + ∇j(o.penalty, o.β, j)
        end
    end

    # update coefficients
    o.β0 -= γ * g0 / n
    for j in 1:p
        o.β[j] -= γ * g[j] / n
    end
    nothing
end

#----------------------------------------------------# special update! for lasso
function update!{M <: SGModel}(o::SGD{M, L1Penalty}, x::AVecF, y::Float64)
    yhat = predict(o, x)
    ε = y - yhat
    γ = weight(o) * o.η

    # intercept (not penalized)
    if o.intercept
        o.β0 -= γ * ∇f(o.model, ε, 1.0, y, yhat)
    end

    # everything else
    if nobs(o) <= o.penalty.burnin
        @inbounds for j in 1:length(x)
            βval = o.β[j]
            u = abs(βval) * (sign(βval) != -1)  # positive/zero coefficient or 0.0
            v = abs(βval) * (sign(βval) == -1)  # negative coefficient or 0.0
            u = max(u - γ * (o.penalty.λ + ∇f(o.model, ε, x[j], y, yhat)), 0.0)
            v = max(v - γ * (o.penalty.λ - ∇f(o.model, ε, x[j], y, yhat)), 0.0)
            o.β[j] = u - v
        end
    else
        @inbounds for j in 1:length(x)
            βval = o.β[j]
            if βval != 0
                u = abs(βval) * (sign(βval) != -1)  # positive/zero coefficient or 0.0
                v = abs(βval) * (sign(βval) == -1)  # negative coefficient or 0.0
                u = max(u - γ * (o.penalty.λ + ∇f(o.model, ε, x[j], y, yhat)), 0.0)
                v = max(v - γ * (o.penalty.λ - ∇f(o.model, ε, x[j], y, yhat)), 0.0)
                o.β[j] = u - v
            end
        end
    end

    o.n += 1
    nothing
end

function updatebatch!{M <: SGModel}(o::SGD{M, L1Penalty}, x::AMatF, y::AVecF)
    γ = weight(o) * o.η

    for i in 1:length(y)
        xi = row(x, i)
        yi = y[i]
        yhat = predict(o, xi)
        ϵ = yi - yhat

        # intercept (not penalized)
        if o.intercept
            o.β0 -= γ * ∇f(o.model, ϵ, 1.0, yi, yhat)
        end

        # everything else
        if nobs(o) <= o.penalty.burnin
            @inbounds for j in 1:length(xi)
                βval = o.β[j]
                u = abs(βval) * (sign(βval) != -1)  # positive/zero coefficient or 0.0
                v = abs(βval) * (sign(βval) == -1)  # negative coefficient or 0.0
                u = max(u - γ * (o.penalty.λ + ∇f(o.model, ϵ, xi[j], yi, yhat)), 0.0)
                v = max(v - γ * (o.penalty.λ - ∇f(o.model, ϵ, xi[j], yi, yhat)), 0.0)
                o.β[j] = u - v
            end
        else
            @inbounds for j in 1:length(xi)
                βval = o.β[j]
                if βval != 0
                    u = abs(βval) * (sign(βval) != -1)  # positive/zero coefficient or 0.0
                    v = abs(βval) * (sign(βval) == -1)  # negative coefficient or 0.0
                    u = max(u - γ * (o.penalty.λ + ∇f(o.model, ϵ, xi[j], yi, yhat)), 0.0)
                    v = max(v - γ * (o.penalty.λ - ∇f(o.model, ϵ, xi[j], yi, yhat)), 0.0)
                    o.β[j] = u - v
                end
            end
        end
        o.n += 1
    end
    nothing
end
