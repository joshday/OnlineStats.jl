#------------------------------------------------------------------------# types
abstract ModelDefinition
abstract IdentityLinkModel <: ModelDefinition
abstract Penalty
abstract Algorithm

#--------------------------------------------------------------# ModelDefinition
immutable L1Regression <: IdentityLinkModel end
immutable L2Regression <: IdentityLinkModel end
immutable LogisticRegression <: ModelDefinition end
immutable PoissonRegression <: ModelDefinition end
immutable QuantileRegression <: IdentityLinkModel
    τ::Float64
    function QuantileRegression(τ::Real = .5)
        @assert 0 < τ < 1
        new(Float64(τ))
    end
end
immutable SVMLike <: IdentityLinkModel end
immutable HuberRegression <: IdentityLinkModel
    δ::Float64
    function HuberRegression(δ::Real = 1.0)
        @assert δ > 0
        new(Float64(δ))
    end
end


@inline ∇f(::L1Regression, yᵢ::Float64, ŷᵢ::Float64) = sign(ŷᵢ - yᵢ)
@inline ∇f(::L2Regression, yᵢ::Float64, ŷᵢ::Float64) = ŷᵢ - yᵢ
@inline ∇f(::LogisticRegression, yᵢ::Float64, ŷᵢ::Float64) = ŷᵢ - yᵢ
@inline ∇f(::PoissonRegression, yᵢ::Float64, ŷᵢ::Float64) = ŷᵢ - yᵢ
@inline ∇f(l::QuantileRegression, yᵢ::Float64, ŷᵢ::Float64) = Float64(yᵢ < ŷᵢ) - l.τ
@inline ∇f(::SVMLike, yᵢ::Float64, ŷᵢ::Float64) = yᵢ * ŷᵢ < 1 ? -yᵢ : 0.0
@inline ∇f(l::HuberRegression, yᵢ::Float64, ŷᵢ::Float64) = abs(yᵢ - ŷᵢ) <= l.δ ? ŷᵢ - yᵢ : l.δ * sign(ŷᵢ - yᵢ)

Base.show(io::IO, o::L1Regression) =        println(io, "L1Regression")
Base.show(io::IO, o::L2Regression) =        println(io, "L2Regression")
Base.show(io::IO, o::QuantileRegression) =  println(io, "QuantileLoss(τ = $(o.τ))")
Base.show(io::IO, o::SVMLike) =             println(io, "SVMLike")
Base.show(io::IO, o::HuberRegression) =     println(io, "HuberRegression(δ = $(o.δ))")

@inline StatsBase.predict(::IdentityLinkModel, x::AVecF, β::VecF, β0::Float64) = dot(x, β) + β0
@inline StatsBase.predict(::IdentityLinkModel, X::AMatF, β::VecF, β0::Float64) = X * β + β0
@inline StatsBase.predict(::LogisticRegression, x::AVecF, β::VecF, β0::Float64) = 1.0 / (1.0 + exp(-dot(x, β) - β0))
@inline StatsBase.predict(::LogisticRegression, X::AMatF, β::VecF, β0::Float64) = 1.0 ./ (1.0 + exp(-X * β - β0))
@inline StatsBase.predict(::PoissonRegression, x::AVecF, β::VecF, β0::Float64) = exp(dot(x, β) + β0)
@inline StatsBase.predict(::PoissonRegression, X::AMatF, β::VecF, β0::Float64) = exp(X*β + β0)

classify(::LogisticRegression, x::AVecF, β, β0) = Float64(predict(o, x) > 0.5)
classify(::SVMLike, x::AVecF, β, β0) = Float64(predict(o, x) > 0.0)


#------------------------------------------------------------------# StochasticModel
"Stochastic models that are linear in the parameters"
type StochasticModel{A<:Algorithm, M<:ModelDefinition, P<:Penalty} <: OnlineStat
    β0::Float64
    β::VecF
    intercept::Bool
    model::M
    penalty::P
    algorithm::A
    n::Int
end

function StochasticModel(
        p::Int;
        intercept::Bool = true,
        model::ModelDefinition = L2Regression(),
        penalty::Penalty = NoPenalty(),
        algorithm::Algorithm = SGD()
    )
    StochasticModel(0.0, zeros(p), intercept, model, penalty, algorithm, 0)
end

function StochasticModel(x::AMatF, y::AVecF; keyargs...)
    o = StochasticModel(size(x, 2); keyargs...)
    update!(o, x, y)
    o
end

@inline StatsBase.predict(o::StochasticModel, x::AVecF) = predict(o.model, x, o.β, o.β0)
@inline StatsBase.predict(o::StochasticModel, X::AMatF) = predict(o.model, X, o.β, o.β0)
alg(o::StochasticModel) = o.algorithm
pen(o::StochasticModel) = o.penalty
StatsBase.coef(o::StochasticModel) = o.intercept ? vcat(o.β0, o.β) : copy(o.β)
classify(o::StochasticModel, x::AVecF) = classify(o.model, x, o.β, o.β0)
classify(o::StochasticModel, x::AMatF) = [classify(o.model, xi, o.β, o.β0) for xi in x]
statenames(o::StochasticModel) = [:β, :nobs]
state(o::StochasticModel) = Any[coef(o), nobs(o)]


function update!(o::StochasticModel, x::AVecF, y::Float64)
    o.n += 1
    updateβ!(o, x, y)
end

function Base.show(io::IO, o::StochasticModel)
    print_with_color(:blue, io, "StochasticModel")
    println(io, "")
    println(io, "  > Intercept:  ", o.intercept)
    println(io, "")
    println(io, "  > Model:      ", o.model)
    println(io, "  > Penalty:    ", o.penalty)
    println(io, "  > Algorithm:  ", o.algorithm)
    print(io, "  > % Nonzero:  ")
    println(io, @sprintf "%3.2f percent" mean(coef(o) .!= 0) * 100)
    println(io, "")
    println(io, "  > β:          ")
    show(coef(o))
end

function Plots.plot(o::StochasticModel)
    x = 1:length(coef(o))
    if o.intercept
        x -= 1
    end
    Plots.scatter(coef(o), legend = false, xlabel = "β", ylabel = "value",
        xlims = extrema(x), yticks = [0])
end
