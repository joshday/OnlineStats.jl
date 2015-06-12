# Sparse Regression

# This is a flexible type that allows users to get ols, ridge, lasso, and elastic net
# estimates from the same object.

# NOTE 1: Only sufficient statistics are updated by update!(), since coefficient
# calculations are expensive.  Instead, coefficients will be calculated by a call
# to coef().

# NOTE 2: X and y are centered/scale, so it is not possible to fit a model without
# an intercept.

#-------------------------------------------------------# Type and Constructors
type SparseReg{W <: Weighting} <: OnlineStat
    c::CovarianceMatrix{W}  # Cov([X y])
    s::MatF                     # "Swept" version of cor(C)
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

mse(o::SparseReg) = o.s[end, end] * o.n / (o.n - size(o.s, 1))

function coef_ols(o::SparseReg)
    o.s = cor(o.c)
    sweep!(o.s, 1:size(o.c.A, 1) - 1)

    μ = mean(o.c)
    σ = std(o.c)
    β = vec(o.s[end, 1:end - 1])
    β₀ = μ[end] - σ[end] * sum(μ[1:end-1] ./ σ[1:end-1] .* β)
    for i in 1:length(β)
        β[i] = β[i] * σ[end] / σ[i]
    end
    return [β₀; β]
end

function coef_ridge(o::SparseReg, λ::Float64)
    p = size(o.c.A, 1) - 1
    o.s = cor(o.c)
    for i in 1:p
        o.s[i, i] += λ
    end
    sweep!(o.s, 1:p)

    μ = mean(o.c)
    σ = std(o.c)
    β = vec(o.s[end, 1:end - 1])
    β₀ = μ[end] - σ[end] * sum(μ[1:end-1] ./ σ[1:end-1] .* β)
    for i in 1:length(β)
        β[i] = β[i] * σ[end] / σ[i]
    end
    return [β₀; β]
end

function coef(o::SparseReg, penalty::Symbol = :ols, λ = 0.)
    if penalty == :ols
        coef_ols(o::SparseReg)
    elseif penalty == :ridge
        coef_ridge(o::SparseReg, λ)
    else
        warn(":$penalty is not a valid option.  Choose :ols, :ridge, :lasso, or :elasticnet.")
    end
end


#---------------------------------------------------------------------# update!
function updatebatch!(o::SparseReg, x::MatF, y::VecF)
    n, p = size(x)
    updatebatch!(o.c, [x y])
    o.n += n
end



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
    path = glmnet(x,y, alpha = 0.)

    # manually create β for ridge
    λ = 1.5
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
end