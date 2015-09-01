
# Regularized Dual Averaging
# http://www.jmlr.org/papers/volume11/xiao10a/xiao10a.pdf
# h(β) = .5 * β'β

#--------------------------------------------------------# Type and Constructors
type RDA{M <: SGModel, P <: Penalty} <: StochasticGradientStat
    β0::Float64
    β::VecF
    intercept::Bool # include intercept?
    g::VecF        # average gradient
    model::M
    penalty::P
    weighting::StochasticWeighting
    η::Float64
    n::Int
end

function RDA(p::Int, wgt::StochasticWeighting = StochasticWeighting();
        penalty::Penalty = NoPenalty(),
        model::SGModel = L2Regression(),
        intercept::Bool = true,
        η = 1.0)
    RDA(0.0, zeros(p), intercept, zeros(p), model, penalty, wgt, η, 0)
end

function RDA(x::AMatF, y::AVecF, wgt::StochasticWeighting = StochasticWeighting(); keyargs...)
    o = RDA(size(x,2), wgt; keyargs...)
    update!(o, x, y)
    o
end


#----------------------------------------------------------------------# update!
function update!(o::RDA, x::AVecF, y::Float64)
    yhat = predict(o, x)
    ε = y - yhat



    #intercept
    if o.intercept
        γ = weight(o)  # only used for intercept
        o.β0 -= γ * ∇f(o.model, ε, 1.0, y, yhat)
    end

    t = nobs(o) / (nobs(o) + 1)
    for j in 1:length(x)
        o.g[j] = t * o.g[j] + (1 - t) * ∇f(o.model, ε, x[j], y, yhat)
    end

    rda_update!(o)
    o.n += 1
end




# These functions do the argmin step:
function rda_update!{M <: SGModel}(o::RDA{M, NoPenalty})
    for j in 1:length(o.β)
        o.β[j] = -sqrt(nobs(o)) * o.η * o.g[j]
    end
end

function rda_update!{M <: SGModel}(o::RDA{M, L1Penalty})
    for j in 1:length(o.β)
        if abs(o.g[j]) <= o.penalty.λ
            o.β[j] = 0.0
        else
            o.β[j] = - sign(o.g[j]) * sqrt(nobs(o)) * o.η *  (abs(o.g[j]) - o.penalty.λ)
        end
    end
end

function rda_update!{M <: SGModel}(o::RDA{M, L2Penalty})
    for j in 1:length(o.β)
        o.β[j] = -sqrt(nobs(o)) * o.g[j] / (sqrt(nobs(o)) * o.penalty.λ + o.η)
    end
end





n, p = 1_000_000, 10
x = randn(n, p)
β = vcat(1.:p)
y = x * β + randn(n)

o = OnlineStats.RDA(x, y, penalty = OnlineStats.L1Penalty(.1))
println(coef(o))
