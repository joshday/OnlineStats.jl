#--------------------------------------------------------------# ModelDefinition
"Minimize `vecnorm(y - Xβ, 2)` with respect to `β`"
immutable L2Regression <: ModelDefinition end
@inline StatsBase.predict(::L2Regression, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline StatsBase.predict(::L2Regression, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline ∇f(::L2Regression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -ϵᵢ * xᵢ


"Minimize `vecnorm(y - Xβ, 1)` with respect to `β`"
immutable L1Regression <: ModelDefinition end
@inline StatsBase.predict(::L1Regression, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline StatsBase.predict(::L1Regression, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline ∇f(::L1Regression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -sign(ϵᵢ) * xᵢ


"Maximize the loglikelihood of a logistic regression model.  For data in {0.0, 1.0}. "
immutable LogisticRegression <: ModelDefinition end  # Logistic regression needs y in {0, 1}
@inline StatsBase.predict(::LogisticRegression, x::AVecF, β::VecF, β0::Float64) = 1.0 / (1.0 + exp(-dot(x, β) - β0))
@inline StatsBase.predict(::LogisticRegression, X::AMatF, β::VecF, β0::Float64) = 1.0 ./ (1.0 + exp(-X * β - β0))
@inline ∇f(::LogisticRegression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -ϵᵢ * xᵢ


"Maximize the loglikelihood of a poisson regresison model.  "
immutable PoissonRegression <: ModelDefinition end
@inline StatsBase.predict(::PoissonRegression, x::AVecF, β::VecF, β0::Float64) = exp(dot(x, β) + β0)
@inline StatsBase.predict(::PoissonRegression, X::AMatF, β::VecF, β0::Float64) = exp(X*β + β0)
@inline ∇f(::PoissonRegression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -ϵᵢ * xᵢ

"Minimize the quantile loss function for the given `τ`"
immutable QuantileRegression <: ModelDefinition
    τ::Float64
    function QuantileRegression(τ::Real = 0.5)
        zero(τ) < τ < one(τ) || error("τ must be in (0, 1)")
        new(@compat Float64(τ))
    end
end
@inline StatsBase.predict(::QuantileRegression, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline StatsBase.predict(::QuantileRegression, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline ∇f(model::QuantileRegression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = ((ϵᵢ < 0) - model.τ) * xᵢ


"`penalty = NoPenalty` is a Perceptron.  `penalty = L2Penalty(λ)` is a support vector machine.  For data in {-1.0, 1.0}.  "
immutable SVMLike <: ModelDefinition end  # SVM needs y in {-1, 1}
@inline StatsBase.predict(::SVMLike, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline StatsBase.predict(::SVMLike, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline ∇f(::SVMLike, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = yᵢ * ŷᵢ < 1 ? -yᵢ * xᵢ : 0.0


"Robust regression using Huber loss"
immutable HuberRegression <: ModelDefinition
    δ::Float64
    function HuberRegression(δ::Real = 1.0)
        δ > 0 || error("parameter must be greater than 0")
        new(@compat Float64(δ))
    end
end
@inline StatsBase.predict(::HuberRegression, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline StatsBase.predict(::HuberRegression, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline function ∇f(mod::HuberRegression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64)
    ifelse(abs(ϵᵢ) <= mod.δ,
        -ϵᵢ * xᵢ,
        -mod.δ * sign(ϵᵢ) * xᵢ
    )
end
