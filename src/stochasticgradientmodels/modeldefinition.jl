#--------------------------------------------------------------# ModelDefinition
# L2 Regression
"Minimize `vecnorm(y - Xβ, 2)` with respect to `β`"
immutable L2Regression <: ModelDefinition end
@inline StatsBase.predict(::L2Regression, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline StatsBase.predict(::L2Regression, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline ∇f(::L2Regression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -ϵᵢ * xᵢ
function loss{A<:SGAlgorithm, P<:Penalty}(o::SGModel{A, L2Regression, P}, x, y)
    yhat = predict(o, x)
    sqrt(sumabs2(y - yhat))
end


# L1 Regression
"Minimize `vecnorm(y - Xβ, 1)` with respect to `β`"
immutable L1Regression <: ModelDefinition end
@inline StatsBase.predict(::L1Regression, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline StatsBase.predict(::L1Regression, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline ∇f(::L1Regression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -sign(ϵᵢ) * xᵢ
function loss{A<:SGAlgorithm, P<:Penalty}(o::SGModel{A, L1Regression, P}, x, y)
    yhat = predict(o, x)
    sumabs(y - yhat)
end


# Logistic Regression
"Maximize the loglikelihood of a logistic regression model.  For data in {0.0, 1.0}. "
immutable LogisticRegression <: ModelDefinition end  # Logistic regression needs y in {0, 1}
@inline StatsBase.predict(::LogisticRegression, x::AVecF, β::VecF, β0::Float64) = 1.0 / (1.0 + exp(-dot(x, β) - β0))
@inline StatsBase.predict(::LogisticRegression, X::AMatF, β::VecF, β0::Float64) = 1.0 ./ (1.0 + exp(-X * β - β0))
classify(m::LogisticRegression, X::AMatF, β::VecF, β0::Float64) = convert(Vector{Int}, X*β + β0 .> 0)
@inline ∇f(::LogisticRegression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -ϵᵢ * xᵢ
function loss{A<:SGAlgorithm, P<:Penalty}(o::SGModel{A, LogisticRegression, P}, x, y)  # misclassification loss
    yhat = classify(o, x)
    sumabs(y - yhat)
end


# Poisson Regression
"Maximize the loglikelihood of a poisson regression model."
immutable PoissonRegression <: ModelDefinition end
@inline StatsBase.predict(::PoissonRegression, x::AVecF, β::VecF, β0::Float64) = exp(dot(x, β) + β0)
@inline StatsBase.predict(::PoissonRegression, X::AMatF, β::VecF, β0::Float64) = exp(X*β + β0)
@inline ∇f(::PoissonRegression, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = -ϵᵢ * xᵢ
function loss{A<:SGAlgorithm, P<:Penalty}(o::SGModel{A, PoissonRegression, P}, x, y)
    yhat = predict(o, x)
    sumabs(y - yhat)
end


# Quantile Regression
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
function loss{A<:SGAlgorithm, P<:Penalty}(o::SGModel{A, QuantileRegression, P}, x, y)
    yhat = predict(o, x)
    d = y - yhat
    for i in 1:length(d)
        d[i] = d[i] * (o.model.τ - (y[i] < yhat[i]))
    end
    sum(d)
end


# SVMLike
"`penalty = NoPenalty` is a Perceptron.  `penalty = L2Penalty(λ)` is a support vector machine.  For data in {-1.0, 1.0}.  "
immutable SVMLike <: ModelDefinition end  # SVM needs y in {-1, 1}
@inline StatsBase.predict(::SVMLike, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline StatsBase.predict(::SVMLike, X::AMatF, β::VecF, β0::Float64) = X * β + β0
classify(m::SVMLike, X::AMatF, β::VecF, β0::Float64) = 2 * (predict(m, X, β, β0) .> 0) - 1
@inline ∇f(::SVMLike, ϵᵢ::Float64, xᵢ::Float64, yᵢ::Float64, ŷᵢ::Float64) = yᵢ * ŷᵢ < 1 ? -yᵢ * xᵢ : 0.0
function loss{A<:SGAlgorithm, P<:Penalty}(o::SGModel{A, SVMLike, P}, x, y)  # misclassification loss
    yhat = classify(o, x)
    sumabs(y - yhat)
end


# Huber Regression
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
function loss{A<:SGAlgorithm, P<:Penalty}(o::SGModel{A, HuberRegression, P}, x, y)
    d = y - predict(o, x)
    for i in 1:length(d)
        if abs(d[i]) > o.model.δ
            d[i] = 0.5 * d[i] ^ 2
        else
            d[i] = o.model.δ * abs(d[i] - 0.5 * o.model.δ)
        end
    end
    sum(d)
end
