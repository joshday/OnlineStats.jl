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
Experimental: Online Sparse Regression

From this type, you can get analytical parameter estimates for OLS, ridge regression,
lasso (TODO), elastic-net (TODO).

You can also specify your own (Convex.jl supported) penalty with coef_solver (TODO)
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
    p = size(o.c.A, 1) - 1
    o.s = cor(o.c)
    for i in 1:p
        o.s[i, i] += λ
    end
    sweep!(o.s, 1:p)
    β = vec(o.s[end, 1:end - 1])
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


function StatsBase.coef(o::SparseReg, penalty::Symbol = :ols, λ::Float64 = 0.0)
    if penalty == :ols
        coef_ols(o::SparseReg)
    elseif penalty == :ridge
        coef_ridge(o::SparseReg, λ)
    else
        error(":$penalty is not a valid option.  Choose :ols or :ridge")
    end
end





#---------------------------------------------------------------------# update!
updatebatch!(o::SparseReg, x::AMatF, y::AVecF) = updatebatch!(o.c, hcat(x, y))

update!(o::SparseReg, x::AVecF, y::Float64) = update!(o.c, vcat(x, y))
update!(o::SparseReg, x::AMatF, y::AVecF) = update!(o.c, hcat(x, y))
