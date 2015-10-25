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

Base.show(io::IO, o::L1Regression) =        print(io, "L1Regression")
Base.show(io::IO, o::L2Regression) =        print(io, "L2Regression")
Base.show(io::IO, o::LogisticRegression) =  print(io, "LogisticRegression")
Base.show(io::IO, o::PoissonRegression) =   print(io, "PoissonRegression")
Base.show(io::IO, o::QuantileRegression) =  print(io, "QuantileLoss(τ = $(o.τ))")
Base.show(io::IO, o::SVMLike) =             print(io, "SVMLike")
Base.show(io::IO, o::HuberRegression) =     print(io, "HuberRegression(δ = $(o.δ))")

∇f(::L1Regression, yᵢ::Float64, ŷᵢ::Float64) =         sign(ŷᵢ - yᵢ)
∇f(::L2Regression, yᵢ::Float64, ŷᵢ::Float64) =         ŷᵢ - yᵢ
∇f(::LogisticRegression, yᵢ::Float64, ŷᵢ::Float64) =   ŷᵢ - yᵢ
∇f(::PoissonRegression, yᵢ::Float64, ŷᵢ::Float64) =    ŷᵢ - yᵢ
∇f(l::QuantileRegression, yᵢ::Float64, ŷᵢ::Float64) =  Float64(yᵢ < ŷᵢ) - l.τ
∇f(::SVMLike, yᵢ::Float64, ŷᵢ::Float64) =              yᵢ * ŷᵢ < 1 ? -yᵢ : 0.0
∇f(l::HuberRegression, yᵢ::Float64, ŷᵢ::Float64) =     abs(yᵢ - ŷᵢ) <= l.δ ? ŷᵢ - yᵢ : l.δ * sign(ŷᵢ - yᵢ)

StatsBase.predict(::IdentityLinkModel, x::AVecF, β::VecF, β0::Float64) =    dot(x, β) + β0
StatsBase.predict(::IdentityLinkModel, X::AMatF, β::VecF, β0::Float64) =    X * β + β0
StatsBase.predict(::LogisticRegression, x::AVecF, β::VecF, β0::Float64) =   1.0 / (1.0 + exp(-dot(x, β) - β0))
StatsBase.predict(::LogisticRegression, X::AMatF, β::VecF, β0::Float64) =   1.0 ./ (1.0 + exp(-X * β - β0))
StatsBase.predict(::PoissonRegression, x::AVecF, β::VecF, β0::Float64) =    exp(dot(x, β) + β0)
StatsBase.predict(::PoissonRegression, X::AMatF, β::VecF, β0::Float64) =    exp(X*β + β0)

classify(m::LogisticRegression, x::AVecF, β, β0) =  Float64(predict(m, x, β, β0) > 0.5)
classify(m::SVMLike, x::AVecF, β, β0) =             Float64(predict(m, x, β, β0) > 0.0)


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

StatsBase.predict(o::StochasticModel, x::AVecF) = predict(o.model, x, o.β, o.β0)
StatsBase.predict(o::StochasticModel, X::AMatF) = predict(o.model, X, o.β, o.β0)
alg(o::StochasticModel) = o.algorithm
pen(o::StochasticModel) = o.penalty
StatsBase.coef(o::StochasticModel) = o.intercept ? vcat(o.β0, o.β) : copy(o.β)
classify(o::StochasticModel, x::AVecF) = classify(o.model, x, o.β, o.β0)
classify(o::StochasticModel, x::AMatF) = [classify(o, row(x,i)) for i in 1:nrows(x)]
statenames(o::StochasticModel) = [:β, :nobs]
state(o::StochasticModel) = Any[coef(o), nobs(o)]


function update!(o::StochasticModel, x::AVecF, y::Float64)
    o.n += 1
    updateβ!(o, x, y)
    nothing
end

function updatebatch!(o::StochasticModel, x::AMatF, y::AVecF)
    o.n += length(y)
    updatebatchβ!(o, x, y)
    nothing
end

# Fall back on this if not implemented
function udpatebatchβ!(o::StochasticModel, x::AMatF, y::AVecF)
    for i in 1:length(y)
        updateβ!(o, rowvec_view(x, i), y[i])
    end
end

function Base.show(io::IO, o::StochasticModel)
    print_with_color(:blue, io, "StochasticModel\n")
    println(io, "  > Nobs:       ", nobs(o))
      print(io, "  > Intercept:  ")
    if o.intercept
        print_with_color(:green, io, string(o.intercept))
    else
        print_with_color(:red, io, string(o.intercept))
    end
    println(io, "")
    println(io, "  > Model:      ", o.model)
    println(io, "  > Penalty:    ", o.penalty)
    println(io, "  > Algorithm:  ", o.algorithm)
    println(io, "  > Sparsity:   ", @sprintf "%3.2f nonzero" mean(coef(o)[1+o.intercept:end] .!= 0))
    println(io, "  > β:          ", coef(o))
end
