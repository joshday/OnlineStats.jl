# Sparse Regression

# This is a flexible type that allows users to get ols and ridge estimates
# TODO: lasso and elastic net

# NOTE 1: Only sufficient statistics are updated by update!() since coefficient
# calculations are expensive.  Instead, coefficients will be calculated by a call
# to coef().

# NOTE 2: X and y are centered/scale, so it is not possible to fit a model without
# an intercept.

#-------------------------------------------------------# Type and Constructors
type SparseReg{W <: Weighting} <: OnlineStat
    c::CovarianceMatrix{W}  # Cov([X y])
    s::MatF                 # memory holder for "Swept" version of cor(o.c)
    n::Int
    weighting::W
end

function SparseReg(x::MatF, y::VecF, wgt::Weighting = default(Weighting))
    n, p = size(x)
    o = SparseReg(p, wgt)
    updatebatch!(o, x, y)
    o
end

function SparseReg(p, wgt::Weighting = default(Weighting))
    c = CovarianceMatrix(p + 1, wgt)
    s = zeros(p + 1, p + 1)
    SparseReg(c, zeros(p + 1, p + 1), 0, wgt)
end


#-----------------------------------------------------------------------# state
statenames(o::SparseReg) = [:β, :nobs]
state(o::SparseReg) = Any[coef(o), nobs(o)]


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

# function path_ridge(o::SparseReg)
#     tmax = sum(coef_ols(o) .^ 2)
#     [i => coef_ridge(o, i)]
# end

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


function coef(o::SparseReg, penalty::Symbol = :ols, λ::Float64 = 0.)
    if penalty == :ols
        coef_ols(o::SparseReg)
    elseif penalty == :ridge
        coef_ridge(o::SparseReg, λ)
    else
        error(":$penalty is not a valid option.  Choose :ols or :ridge")
    end
end





#---------------------------------------------------------------------# update!
function updatebatch!(o::SparseReg, x::MatF, y::VecF)
    n = size(x, 1)
    updatebatch!(o.c, [x y])
    o.n += n
end

function update!(o::SparseReg, x::VecF, y::Float64)
    update!(o.c, [x; y])
    o.n += 1
end

update!(o::SparseReg, x::MatF, y::VecF) = (update!(o.c, [x y]); o.n += length(y))


# testing
if false
    using StatsBase
    using GLM
    n, p = 10000, 200
    o = OnlineStats.SparseReg(p)

    x = randn(n, p)
    β = [1:5; zeros(p - 5)]
    y = x * β + randn(n)

    OnlineStats.updatebatch!(o, x, y); coef(o)
    glm = lm([ones(n) x],y);

    # manually create β for ridge
    λ = 1.
    lambdamat = eye(p) * λ
    βridge = inv(cor(x) + lambdamat) * vec(cor(x, y))
    μ = mean(o.c)
    σ = std(o.c)
    β₀ = μ[end] - σ[end] * sum(μ[1:end-1] ./ σ[1:end-1] .* βridge)
    βridge = σ[end] * (βridge ./ σ[1:end-1])
    βridge = [β₀; βridge]

    maxabs(coef(glm) - coef(o))
    maxabs(coef(o, :ridge, 0.) - coef(o))
    maxabs(coef(o, :ridge, λ) - βridge)

    βridgesolver = OnlineStats.coef_solver(o, λ, x -> .5 * Convex.sum_squares(x))
    maxabs(coef(o, :ridge, λ) - βridgesolver)
end
