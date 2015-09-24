# Sparse Regression
#
# NOTE 1: Only sufficient statistics are updated by update!() since coefficient
# calculations are expensive.  Instead, coefficients will be calculated by a call
# to coef().
#
# NOTE 2: X and y are centered/scale, so it is not possible to fit a model without
# an intercept.
#-------------------------------------------------------# Type and Constructors
"""
Online Sparse Regression

Analytical parameter estimates for ordinary least squares, ridge regression, LASSO,
and elastic net.
"""
type SparseReg{W <: Weighting} <: OnlineStat
    c::CovarianceMatrix{W}  # Cov([X y])
    s::MatF                 # memory holder for "Swept" version of cor(o.c)
    weighting::W
end

function SparseReg(x::AMatF, y::AVecF, wgt::Weighting = default(Weighting))
    p = size(x, 2)
    o = SparseReg(p, wgt)
    updatebatch!(o, x, y)
    o
end

function SparseReg(p::Integer, wgt::Weighting = default(Weighting))
    c = CovarianceMatrix(p + 1, wgt)
    s = zeros(p + 1, p + 1)
    SparseReg(c, zeros(p + 1, p + 1), wgt)
end


#-----------------------------------------------------------------------# state
statenames(o::SparseReg) = [:β, :nobs]
state(o::SparseReg) = Any[coef(o), nobs(o)]
nobs(o::SparseReg) = nobs(o.c)


#-----------------------------------------------------------------------# coef

# Assumes mean(y) == μ[end], std(y) == σ[end]
# put centered/scaled predictors into original scale
@inline function scaled_to_original!(β, μ, σ)
    β₀ = μ[end] - σ[end] * sum(μ[1:end-1] ./ σ[1:end-1] .* β)
    for i in 1:length(β)
        β[i] = β[i] * σ[end] / σ[i]
    end
    return [β₀; β]
end

# NoPenalty
function StatsBase.coef(o::SparseReg, penalty::NoPenalty = NoPenalty())
    o.s = cor(o.c)
    sweep!(o.s, 1:size(o.c.A, 1) - 1)
    β = vec(o.s[end, 1:end - 1])
    scaled_to_original!(β, mean(o.c), std(o.c))
end

# L2Penalty
function StatsBase.coef(o::SparseReg, penalty::L2Penalty)
    p = length(o.c.B) - 1
    λ = penalty.λ
    o.s = cor(o.c)
    for i in 1:p
        o.s[i, i] += λ
    end
    sweep!(o.s, 1:p)
    β = vec(o.s[end, 1:end - 1])
    scaled_to_original!(β, mean(o.c), std(o.c))
end

# L1Penalty, ElasticNetPenalty, SCADPenalty
function StatsBase.coef(o::SparseReg, penalty::Penalty;
        maxiters::Integer = 50,
        tolerance::Float64 = 1e-4,
        verbose::Bool = true,
        step::Float64 = 1.0
        )
    p = length(o.c.B) - 1  # Number of predictors (not including intercept)
    o.s = cor(o.c)  # cor(hcat(x, y))
    β = zeros(p)
    tol = 0.0
    iters = 0

    xtx = o.s[1:p, 1:p]  # x'x
    xty = o.s[1:p, end]  # x'y

    for i in 1:maxiters
        iters += 1
        βold = copy(β)
        gradient = (xty - xtx * β)
        β = β + step * gradient  # β + step * x'(y - x * β)
        prox!(β, penalty, step)

        # Try step halving a few times if objective isn't decreased
        k = 1
        old_objective = ℓ(βold, xtx, xty, penalty)
        while ℓ(β, xtx, xty, penalty) > old_objective
            s = 0.5 ^ k * step
            β = βold + s * gradient
            prox!(β, penalty, s)
            k += 1
            k > 5 && break  # This will try step halving 6 times
        end

        tol = βtol(β, βold, xtx, xty, penalty)
        tol < tolerance && break
    end

    tol < tolerance || warn("Algorithm did not achieve convergence")
    verbose && println("tolerance:                ", tol)
    verbose && println("iterations:               ", iters)
    verbose && println("penalized log-likelihood: ", ℓ(β, xtx, xty, penalty))
    scaled_to_original!(β, mean(o.c), std(o.c))
end

# L1Penalty: J(β) = vecnorm(β, 1)
function prox!(β::VecF, penalty::L1Penalty, step::Float64)
    for j in 1:length(β)
        β[j] = sign(β[j]) * max(abs(β[j]) - step * penalty.λ, 0.0)  # soft-thresholding step
    end
end

# ElasticNetPenalty: J(β) = (α * vecnorm(β,1) + (1 - α) * .5 * vecnorm(β, 2))
function prox!(β::AVecF, penalty::ElasticNetPenalty, step::Float64)
    for j in 1:length(β)
        β[j] = sign(β[j]) * max(abs(β[j]) - step * penalty.λ * penalty.α, 0.0)  # Lasso prox
        β[j] = β[j] / (1.0 + step * penalty.λ * (1.0 - penalty.α))              # Ridge prox
    end
end

# SCADPenalty
function prox!(β::AVecF, penalty::SCADPenalty, step::Float64)
    for j in 1:length(β)
        βj = β[j]
        if abs(βj) > penalty.a * penalty.λ
        elseif abs(βj) < 2.0 * penalty.λ
            β[j] = sign(βj) * max(abs(βj) - step * penalty.λ, 0.0)
        else
            β[j] = (βj - step * sign(βj) * penalty.a * penalty.λ / (penalty.a - 1.0)) / (1.0 - (1.0 / penalty.a - 1.0))
        end
    end
end



# convergence criteria for lasso/elasticnet
function ℓ(β::VecF, xtx::MatF, xty::VecF, penalty::Penalty)
    dot(β, xtx * β) - 2.0 * dot(β, xty) + _j(penalty, β)
end

function βtol(β::VecF, βold::VecF, xtx::MatF, xty::VecF, penalty::Penalty)
    v = ℓ(β, xtx, xty, penalty)
    u = ℓ(βold, xtx, xty, penalty)
    abs(u - v) / (abs(v) + 1.0)
end



#---------------------------------------------------------------------# update!
updatebatch!(o::SparseReg, x::AMatF, y::AVecF) = updatebatch!(o.c, hcat(x, y))

update!(o::SparseReg, x::AVecF, y::Float64) = update!(o.c, vcat(x, y))
update!(o::SparseReg, x::AMatF, y::AVecF) = update!(o.c, hcat(x, y))
