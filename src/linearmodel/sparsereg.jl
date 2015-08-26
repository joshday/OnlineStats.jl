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

Analytical parameter estimates for ordinary least squares and ridge regression.
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

@inline _ℓ(β, xtx, xty, λ) = dot(β, xtx * β) + dot(β, xty) + λ * sumabs(β)

# Proximal gradient algorithm
function coef_lasso(o::SparseReg, λ::Float64;
        maxiters::Integer = 10, tolerance::Real = 1e-4, verbose::Bool = true)
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
        β = β + xty - xtx * β
        for j in 1:p
            β[j] = sign(β[j]) * max(abs(β[j]) - λ, 0.0)
        end
        tol = abs(_ℓ(βold, xtx, xty, λ) - _ℓ(β, xtx, xty, λ)) / (abs(_ℓ(β, xtx, xty, λ)) + 1.0)
        tol < tolerance && break
    end

    verbose && println("tolerance: ", tol); println("iterations: ", iters)
    scaled_to_original(β, mean(o.c), std(o.c))
end


# # Take a user-defined penalty (a function supported by Convex.jl)
# # and plug it into a Convex Solver
# # objective is to minimize: .5 * β' * cor(x) * β - cor(x, y) * β + J(β)
# function coef_solver(o::SparseReg, λ::Float64, penalty::Function,
#                      solver::AbstractMathProgSolver = Convex.get_default_solver())
#     o.s = cor(o.c)
#     β = Convex.Variable(size(o.c.A, 1) - 1)
#     p = Convex.minimize(.5 * Convex.quad_form(β, o.s[1:end-1, 1:end-1]) - vec(o.s[end, 1:end-1])' * β + λ * penalty(β))
#     Convex.solve!(p, SCS.SCSSolver(verbose = true))
#     scaled_to_original(β.value, mean(o.c), std(o.c))
# end


function StatsBase.coef(o::SparseReg, penalty::Symbol = :ols, λ::Float64 = 0.0; keyargs...)
    if penalty == :ols
        coef_ols(o)
    elseif penalty == :ridge
        coef_ridge(o, λ)
    elseif penalty == :lasso
        coef_lasso(o, λ; keyargs...)
    else
        error(":$penalty is not a valid option.  Choose :ols, :ridge, or :lasso")
    end
end





#---------------------------------------------------------------------# update!
updatebatch!(o::SparseReg, x::AMatF, y::AVecF) = updatebatch!(o.c, hcat(x, y))

update!(o::SparseReg, x::AVecF, y::Float64) = update!(o.c, vcat(x, y))
update!(o::SparseReg, x::AMatF, y::AVecF) = update!(o.c, hcat(x, y))
