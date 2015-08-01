# Need structure to accomodate the following model types:
#  L1 Regression
#  L2 Regression
#  Logistic Regression
#  Poisson Regression
#  Quantile Regression
#  SVM (hinge and smoothed-hinge loss?)
#  Huber loss regression

# ∇f takes some unused arguments to accomodate each loss function

abstract SGModel # Stochastic Gradient Model

"Minimize `vecnorm(y - Xβ, 2)` with respect to `β`"
immutable L2Regression <: SGModel end
@inline predict(::L2Regression, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline predict(::L2Regression, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline ∇f(::L2Regression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -ϵᵢ * xᵢ


"Minimize `vecnorm(y - Xβ, 1)` with respect to `β`"
immutable L1Regression <: SGModel end
@inline predict(::L1Regression, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline predict(::L1Regression, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline ∇f(::L1Regression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -sign(ϵᵢ) * xᵢ


"Minimize the negative loglikelihood of a logistic regression model"
immutable LogisticRegression <: SGModel end  # Logistic regression needs y in {0, 1}
@inline predict(::LogisticRegression, x::AVecF, β::VecF, β0::Float64) = 1.0 / (1.0 + exp(-dot(x, β) - β0))
@inline predict(::LogisticRegression, X::AMatF, β::VecF, β0::Float64) = 1.0 ./ (1.0 + exp(-X * β - β0))
@inline ∇f(::LogisticRegression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -ϵᵢ * xᵢ


# NOTE: Likelihood based version (L2 loss) is super unstable.
# Instead, this uses an L1 loss, which is NOT the same as maximizing the likelihood.
# This seems to work for now, but I need to figure out the right way to do this
"Poisson regression via an L1 loss function (since likelihood-based updates are unstable)"
immutable PoissonRegression <: SGModel end
@inline predict(::PoissonRegression, x::AVecF, β::VecF, β0::Float64) = exp(dot(x, β) + β0)
@inline predict(::PoissonRegression, X::AMatF, β::VecF, β0::Float64) = exp(X*β + β0)
@inline ∇f(::PoissonRegression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -sign(ϵᵢ) * xᵢ

"Minimize the quantile loss function for the given `τ`"
immutable QuantileRegression <: SGModel
    τ::Float64
    function QuantileRegression(τ::Real = 0.5)
        zero(τ) < τ < one(τ) || error("τ must be in (0, 1)")
        new(@compat Float64(τ))
    end
end
@inline predict(::QuantileRegression, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline predict(::QuantileRegression, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline ∇f(model::QuantileRegression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = ((ϵᵢ < 0) - model.τ) * xᵢ


# Note: Perceptron if NoPenalty, SVM if L2Penalty
"`penalty = NoPenalty` is a Perceptron.  `penalty = L2Penalty` is a support vector machine"
immutable SVMLike <: SGModel end  # SVM needs y in {-1, 1}
@inline predict(::SVMLike, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline predict(::SVMLike, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline ∇f(::SVMLike, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = yᵢ * ŷᵢ < 1 ? -yᵢ * xᵢ : 0.0


"Robust regression using Huber loss"
immutable HuberRegression <: SGModel
    δ::Float64
    function HuberRegression(δ::Real = 1.0)
        δ > 0 || error("parameter must be greater than 0")
        new(@compat Float64(δ))
    end
end
@inline predict(::HuberRegression, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline predict(::HuberRegression, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline function ∇f(mod::HuberRegression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64)
    ifelse(abs(ϵᵢ) <= mod.δ,
        -ϵᵢ * xᵢ,
        -mod.δ * sign(ϵᵢ) * xᵢ
    )
end


#----------------------------------------------------------------------# Penalty
abstract Penalty

# J(β) = 0.0
immutable NoPenalty <: Penalty end
@inline ∇j(::NoPenalty, β::VecF, i::Int) = 0.0

# J(β) = λ * sumabs(β)
immutable L1Penalty <: Penalty
  λ::Float64
end
@inline ∇j(reg::L1Penalty, β::VecF, i::Int) = reg.λ * sign(β[i])

# J(β) = λ * sumabs2(β)
# LASSO models need a special update which effectively doubles the number of parameters
# Doubling parameters however gives the benefit of a sparse solution
immutable L2Penalty <: Penalty
  λ::Float64
end
@inline ∇j(reg::L2Penalty, β::VecF, i::Int) = reg.λ * β[i]
