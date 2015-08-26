# Sparse Regression

# This is a flexible type that allows users to get ols and ridge estimates
# TODO: lasso and elastic net

# NOTE 1: Only sufficient statistics are updated by update!() since coefficient
# calculations are expensive.  Instead, coefficients will be calculated by a call
# to coef().

# NOTE 2: X and y are centered/scale, so it is not possible to fit a model without
# an intercept.

#-------------------------------------------------------# Type and Constructors
"""
Online Sparse Regression

Analytical parameter estimates for ordinary least squares, ridge regression, and
the LASSO.
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
function scaled_to_original(β, μ, σ)
    β₀ = μ[end] - σ[end] * sum(μ[1:end-1] ./ σ[1:end-1] .* β)
    for i in 1:length(β)
        β[i] = β[i] * σ[end] / σ[i]
    end
    return [β₀; β]
end

function coef_ols(o::SparseReg)
    o.s = cor(o.c)
    sweep!(o.s, 1:size(o.c.A, 1) - 1)
    β = vec(o.s[end, 1:end - 1])
    scaled_to_original(β, mean(o.c), std(o.c))
end

function coef_ridge(o::SparseReg, λ::Float64)
    p = length(o.c.B) - 1
    o.s = cor(o.c)
    for i in 1:p
        o.s[i, i] += λ
    end
    sweep!(o.s, 1:p)
    β = vec(o.s[end, 1:end - 1])
    scaled_to_original(β, mean(o.c), std(o.c))
end


# These functions should be passed as arguments to coef_prox
# J(β) = vecnorm(β, 1)
function prox_lasso!(β::AVecF, λ::Float64, α::Float64 = 0.0)
    for j in 1:length(β)
        β[j] = sign(β[j]) * max(abs(β[j]) - λ, 0.0)  # soft-thresholding step
    end
end

# J(β) = (α * vecnorm(β,1) + (1 - α) * .5 * vecnorm(β, 2))
function prox_elasticnet!(β::AVecF, λ::Float64, α::Float64)
    prox_lasso!(β, λ * α)
    for j in 1:length(β)
        β[j] = β[j] / (1.0 + λ * (1.0 - α))
    end
end




@inline _ℓ(β, xtx, xty, λ) = dot(β, xtx * β) + dot(β, xty) + λ * sumabs(β)

# Proximal gradient descent
function coef_prox(o::SparseReg, prox!::Function, λ::Float64, α::Float64 = 0.0;
        maxiters::Integer = 10, tolerance::Float64 = 1e-4, verbose::Bool = true, step::Float64 = 1.0)
    p = length(o.c.B) - 1
    o.s = cor(o.c)
    β = zeros(p)
    tol = Inf
    iters = 0

    xtx = o.s[1:p, 1:p]
    xty = o.s[1:p, end]

    for i in 1:maxiters
        iters += 1
        βold = copy(β)
        β = β + step * (xty - xtx * β)  # β + x'(y - x*β)
        prox!(β, λ, α)
        tol = abs(_ℓ(βold, xtx, xty, λ) - _ℓ(β, xtx, xty, λ)) / (abs(_ℓ(β, xtx, xty, λ)) + 1.0)
        tol < tolerance && break
    end

    verbose && println("tolerance:  ", tol)
    verbose && println("iterations: ", iters)
    scaled_to_original(β, mean(o.c), std(o.c))
end

function StatsBase.coef(o::SparseReg, penalty::Symbol = :ols, λ::Float64 = 0.0, α = 0.0; keyargs...)
    if penalty == :ols
        coef_ols(o)
    elseif penalty == :ridge
        coef_ridge(o, λ)
    elseif penalty == :lasso
        coef_prox(o, prox_lasso!, λ; keyargs...)
    elseif penalty == :elasticnet
        coef_prox(o, prox_elasticnet!, λ, α; keyargs...)
    else
        error(":$penalty unrecognized.  Choose :ols, :ridge, :lasso, or :elasticnet")
    end
end





#---------------------------------------------------------------------# update!
updatebatch!(o::SparseReg, x::AMatF, y::AVecF) = updatebatch!(o.c, hcat(x, y))

update!(o::SparseReg, x::AVecF, y::Float64) = update!(o.c, vcat(x, y))
update!(o::SparseReg, x::AMatF, y::AVecF) = update!(o.c, hcat(x, y))
