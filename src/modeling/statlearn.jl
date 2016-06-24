#---------------------------------------------------------------------# ModelDefinition
include("penalty.jl")
abstract Algorithm
abstract ModelDefinition
abstract GLMDef <: ModelDefinition

immutable L2Regression          <: GLMDef end
immutable L1Regression          <: ModelDefinition end
immutable LogisticRegression    <: GLMDef end
immutable PoissonRegression     <: GLMDef end
immutable QuantileRegression    <: ModelDefinition
    τ::Float64
    function QuantileRegression(τ::Real = .5)
        @assert 0 < τ < 1
        new(Float64(τ))
    end
end
immutable SVMLike <: ModelDefinition end
immutable HuberRegression <: ModelDefinition
    δ::Float64
    function HuberRegression(δ::Real = 1.0)
        @assert δ > 0
        new(Float64(δ))
    end
end

Base.show(io::IO, o::L2Regression) =        print(io, "L2Regression")
Base.show(io::IO, o::L1Regression) =        print(io, "L1Regression")
Base.show(io::IO, o::LogisticRegression) =  print(io, "LogisticRegression")
Base.show(io::IO, o::PoissonRegression) =   print(io, "PoissonRegression")
Base.show(io::IO, o::QuantileRegression) =  print(io, "QuantileRegression (τ = $(o.τ))")
Base.show(io::IO, o::SVMLike) =             print(io, "SVMLike")
Base.show(io::IO, o::HuberRegression) =     print(io, "HuberRegression (δ = $(o.δ))")

# x is Vector
predict(o::L2Regression, x::AVec, β0, β) =        β0 + dot(x, β)
predict(o::L1Regression, x::AVec, β0, β) =        β0 + dot(x, β)
predict(o::LogisticRegression, x::AVec, β0, β) =  1.0 / (1.0 + exp(-β0 - dot(x, β)))
predict(o::PoissonRegression, x::AVec, β0, β) =   exp(β0 + dot(x, β))
predict(o::QuantileRegression, x::AVec, β0, β) =  β0 + dot(x, β)
predict(o::SVMLike, x::AVec, β0, β) =             β0 + dot(x, β)
predict(o::HuberRegression, x::AVec, β0, β) =     β0 + dot(x, β)

classify(o::LogisticRegression, x::AVec, β0, β) = Float64(β0 + dot(x, β) > 0.0)
classify(o::SVMLike, x::AVec, β0, β) = sign(β0 + dot(x, β))

function StatsBase.predict{T<:Real}(o::ModelDefinition, x::AMat{T}, β0::Float64, β::VecF)
    [predict(o, row(x, i), β0, β) for i in 1:size(x, 1)]
end
function classify{T<:Real}(o::ModelDefinition, x::AMat{T}, β0::Float64, β::VecF)
    [classify(o, row(x, i), β0, β) for i in 1:size(x, 1)]
end


# y and η are Vectors
loss(::L2Regression, y, η) = 0.5 * mean(abs2(y - η))
loss(::L1Regression, y, η) = mean(abs(y - η))
loss(::LogisticRegression, y, η) = mean(-y .* η + log(1.0 + exp(η)))
loss(::PoissonRegression, y, η) = mean(-y .* η + exp(η))
loss(m::QuantileRegression, y, η) =
    mean([(y[i] - η[i]) * (m.τ - Float64(y[i] < η[i])) for i in 1:length(y)])
loss(m::SVMLike, y, η) =
    mean([max(0.0, 1.0 - y[i] * η[i]) for i in 1:length(y)])
function loss(m::HuberRegression, y, η)
    mean([
        abs(y[i] - η[i]) < m.δ ?
        0.5 * (y[i] - η[i])^2 :
        m.δ * (abs(y[i] - η[i]) - 0.5 * m.δ)
        for i in 1:length(y)
        ])
end



deriv(o::GLMDef, y::Real, ŷ::Real) = ŷ - y  # Canonical link GLMs
deriv(o::L1Regression, y::Real, ŷ::Real) = sign(ŷ - y)
deriv(m::QuantileRegression, y::Real, ŷ::Real) = Float64(y < ŷ) - m.τ
deriv(m::SVMLike, y::Real, ŷ::Real) = y * ŷ < 1 ? -y : 0.0
deriv(m::HuberRegression, y::Real, ŷ::Real) = abs(y - ŷ) <= m.δ ? ŷ - y : m.δ * sign(ŷ - y)



#--------------------------------------------------------------------# Algorithm
abstract Algorithm


#--------------------------------------------------------------------# StatLearn
"""
Online statistical learning algorithms.

- `StatLearn(p)`
- `StatLearn(x, y)`
- `StatLearn(x, y, b)`

The model is defined by:

#### `ModelDefinition`

- `L2Regression()`
    - Squared error loss.  Default.
- `L1Regression()`
    - Absolute loss
- `LogisticRegression()`
    - Model for data in {0, 1}
- `PoissonRegression()`
    - Model count data {0, 1, 2, 3, ...}
- `QuantileRegression(τ)`
    - Model conditional quantiles
- `SVMLike()`
    - For data in {-1, 1}.  Perceptron with `NoPenalty`. SVM with `RidgePenalty`.
- `HuberRegression(δ)`
    - Robust Huber loss

#### `Penalty`
- `NoPenalty()`
    - No penalty.  Default.
- `RidgePenalty(λ)`
    - Ridge regularization: `dot(β, β)`
- `LassoPenalty(λ)`
    - Lasso regularization: `sumabs(β)`
- `ElasticNetPenalty(λ, α)`
    - Ridge/LASSO weighted average.  `α = 0` is Ridge, `α = 1` is LASSO.
- `SCADPenalty(λ, a = 3.7)`
    - Smoothly clipped absolute deviation penalty.  Essentially LASSO with less bias
    for larger coefficients.

#### `Algorithm`
- `SGD()`
    - Stochastic gradient descent.  Default.
- `AdaGrad()`
    - Adaptive gradient method. Ignores `Weight`.
- `AdaDelta()`
    - Extension of AdaGrad.  Ignores `Weight`.
- `RDA()`
    - Regularized dual averaging with ADAGRAD.  Ignores `Weight`.
- `MMGrad()`
    - Experimental online MM gradient method.

**Note:** The order of the `ModelDefinition`, `Penalty`, and `Algorithm` arguments don't matter.

```julia
StatLearn(x, y)
StatLearn(x, y, AdaGrad())
StatLearn(x, y, MMGrad(), LearningRate(.5))
StatLearn(x, y, 10, LearningRate(.7), RDA(), SVMLike(), RidgePenalty(.1))
```
"""
type StatLearn{
        A <: Algorithm,
        M <: ModelDefinition,
        P <: Penalty,
        W <: Weight} <: OnlineStat{XYInput}
    β0::Float64     # intercept
    β::VecF         # coefficients
    intercept::Bool # should β0 be estimated?
    algorithm::A    # determines how updates work
    model::M        # model definition
    η::Float64      # constant part of learning rate
    penalty::P      # type of penalty
    weight::W       # Weight, may not get used, depending on algorithm
end
function _StatLearn(p::Integer, wgt::Weight = LearningRate();
        model::ModelDefinition = L2Regression(),
        η::Real = 1.0,
        penalty::Penalty = NoPenalty(),
        algorithm::Algorithm = SGD(),
        intercept::Bool = true
    )
    o = StatLearn(0.0, zeros(p), intercept, algorithm, model, Float64(η), penalty, wgt)
    o.algorithm = typeof(o.algorithm)(p, o.algorithm)
    o
end
function StatLearn(p::Integer, args...; kw...)
    wgt = LearningRate()
    mod = L2Regression()
    alg = SGD()
    pen = NoPenalty()
    for arg in args
        T = typeof(arg)
        if T <: Weight
            wgt = arg
        elseif T <: ModelDefinition
            mod = arg
        elseif T <: Algorithm
            alg = arg
        elseif T <: Penalty
            pen = arg
        end
    end
    _StatLearn(p, wgt; model = mod, algorithm = alg, penalty = pen, kw...)
end
function StatLearn(x::AMat, y::AVec, args...; kw...)
    o = StatLearn(size(x, 2), args...; kw...)
    fit!(o, x, y)
    o
end
function StatLearn(x::AMat, y::AVec, b::Integer, args...; kw...)
    o = StatLearn(size(x, 2), args...; kw...)
    fit!(o, x, y, b)
    o
end
StatsBase.coef(o::StatLearn) = value(o)
StatsBase.predict{T<:Real}(o::StatLearn, x::AVec{T}) = predict(o.model, x, o.β0, o.β)
StatsBase.predict{T<:Real}(o::StatLearn, x::AMat{T}) = predict(o.model, x, o.β0, o.β)
classify{T<:Real}(o::StatLearn, x::AVec{T}) = classify(o.model, x, o.β0, o.β)
classify{T<:Real}(o::StatLearn, x::AMat{T}) = classify(o.model, x, o.β0, o.β)
value(o::StatLearn) = o.intercept ? vcat(o.β0, o.β) : o.β
Base.ndims(o::StatLearn) = length(o.β) + o.intercept
function Base.show(io::IO, o::StatLearn)
    printheader(io, "StatLearn")
    print_item(io, "value", coef(o))
    print_item(io, "model", o.model)
    print_item(io, "penalty", o.penalty)
    print_item(io, "algorithm", o.algorithm)
    print_item(io, "nobs", nobs(o))
end
function _fit!{T<:Real}(o::StatLearn, x::AVec{T}, y::Real, γ::Float64)
    length(x) == length(o.β) || error("x is incorrect length")
    ŷ = predict(o, x)
    g = deriv(o.model, y, ŷ)
    _updateβ!(o, g, x, y, ŷ, γ)
    o
end
function _fitbatch!{T<:Real, S<:Real}(o::StatLearn, x::AMat{T}, y::AVec{S}, γ::Float64)
    size(x, 2) == length(o.β) || error("x has incorrect number of columns")
    ŷ = predict(o, x)
    g = zeros(length(ŷ))
    for i in eachindex(g)
        @inbounds g[i] = deriv(o.model, y[i], ŷ[i])
    end
    _updatebatchβ!(o, g, x, y, ŷ, γ)
    o
end
setβ0!(o::StatLearn, γ, g) = (o.β0 = subgrad(o.β0, γ, g))
loss(o::StatLearn, x::AMat, y::AVec) = loss(o.model, y, o.β0 + x * o.β)

cost(o::StatLearn, x::AVec, y::Real) =
    loss(o.model, y, o.β0 + dot(x, o.β)) + _j(o.penalty, o.β)
cost(o::StatLearn, x::AMat, y::AVec) =
    loss(o.model, y, o.β0 + x * o.β) + _j(o.penalty, o.β)



#==============================================================================#
#                                                           Updates by Algorithm
#==============================================================================#
# For Adaptive Proximal Methods (everything but SGD), the step argument for prox should be:
# step = η * γ / o.algorithm.h[j]

function batch_g(xj::AVec, g::AVec)
    v = 0.0
    n = length(xj)
    for i in 1:n
        @inbounds v += xj[i] * g[i]
    end
    v / n
end

#-------------------------------------------------------------------------------# SGD
immutable SGD <: Algorithm
    SGD() = new()
    SGD(p::Integer, alg::SGD) = new()
end
function _updateβ!(o::StatLearn{SGD}, g, x, y, ŷ, γ)
    step = o.η * γ
    o.intercept && setβ0!(o, step, g)
    for j in eachindex(o.β)
        Δ = add_deriv(o.penalty, g * x[j], o.β[j])
        @inbounds o.β[j] = o.β[j] - step * Δ
    end
end
function _updatebatchβ!(o::StatLearn{SGD}, g::AVec, x::AMat, y::AVec, ŷ::AVec, γ)
    n2 = length(y)
    step = o.η * γ
    o.intercept && setβ0!(o, step, mean(g))
    for j in eachindex(o.β)
        gj = batch_g(sub(x, :, j), g)
        Δ = add_deriv(o.penalty, gj, o.β[j])
        o.β[j] = o.β[j] - step * Δ
    end
end


#-----------------------------------------------------------------------------# FOBOS
immutable FOBOS <: Algorithm
    FOBOS() = new()
    FOBOS(p::Integer, alg::FOBOS) = new()
end
function _updateβ!(o::StatLearn{FOBOS}, g, x, y, ŷ, γ)
    step = o.η * γ
    o.intercept && setβ0!(o, step, g)
    for j in eachindex(o.β)
        o.β[j] = prox(o.penalty, o.β[j] - step * g * x[j], step)
    end
end
function _updatebatchβ!(o::StatLearn{FOBOS}, g::AVec, x::AMat, y::AVec, ŷ::AVec, γ)
    n2 = length(y)
    step = γ * o.η
    o.intercept && setβ0!(o, step, mean(g))
    for j in eachindex(o.β)
        gj = batch_g(sub(x, :, j), g)
        o.β[j] = prox(o.penalty, o.β[j] - step * gj, step)
    end
end


#--------------------------------------------------------------------------# SGD2
# Uses "stochastic average" of diagonals from Hessian matrix
type SGD2 <: Algorithm
    d0::Float64
    d::VecF
    SGD2() = new()
    SGD2(p::Integer, alg::SGD2) = new(0.0, zeros(p))
end
function _updateβ!(o::StatLearn{SGD2}, g, x, y, ŷ, γ)
    ηγ = o.η * γ
    alg = o.algorithm
    if o.intercept
        alg.d0 = smooth(alg.d0, denom(o.model, g, 1.0, y, ŷ), γ)
        step = ηγ / (alg.d0 + _ϵ)
        setβ0!(o, step, g)
    end
    for j in eachindex(o.β)
        alg.d[j] = smooth(alg.d[j], denom(o.model, g, x[j], y, ŷ), γ)
        step = ηγ / (alg.d[j] + _ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - step * g * x[j], step)
    end
end
function _updatebatchβ!(o::StatLearn{SGD2}, g::AVec, x::AMat, y::AVec, ŷ::AVec, γ)
    n = length(y)
    ηγ = o.η * γ
    alg = o.algorithm
    if o.intercept
        v = 0.0
        for i in 1:n
            v += denom(o.model, g[i], 1.0, y[i], ŷ[i])
        end
        alg.d0 = smooth(alg.d0, v / n, γ)
        step = ηγ / (alg.d0 + _ϵ)
        setβ0!(o, step, mean(g))
    end
    for j in eachindex(o.β)
        v = 0.0
        for i in 1:n
            v += denom(o.model, g[i], x[i, j], y[i], ŷ[i])
        end
        v /= n
        gx = batch_g(sub(x, :, j), g)
        alg.d[j] = smooth(alg.d[j], v / n, γ)
        step = ηγ / (alg.d[j] + _ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - step * gx, step)
    end
end
denom(::L2Regression, g, xj, y, ŷ)         = xj * xj
denom(::LogisticRegression, g, xj, y, ŷ)   = xj * xj * ŷ * (1.0 - ŷ)
denom(::PoissonRegression, g, xj, y, ŷ)    = xj * xj * ŷ
denom(::ModelDefinition, g, xj, y, ŷ)      = error("SGD2 only derived for GLMs")


#---------------------------------------------------------------------------# AdaGrad
type AdaGrad <: Algorithm
    g0::Float64
    g::VecF
    AdaGrad() = new()
    AdaGrad(p::Integer, alg::AdaGrad) = new(0.0, zeros(p))
end
function _updateβ!(o::StatLearn{AdaGrad}, g, x, y, ŷ, γ)
    alg = o.algorithm
    ηγ = o.η * γ
    w = 1 / o.weight.nups  # for updating denominators
    if o.intercept
        alg.g0 += g * g
        alg.g0 = smooth(alg.g0, g * g, w)
        step = ηγ / (sqrt(alg.g0) + _ϵ)
        setβ0!(o, step, g)
    end
    for j in 1:length(o.β)
        gx = g * x[j]
        alg.g[j] = smooth(alg.g[j], gx * gx, w)
        step = ηγ / (sqrt(alg.g[j]) + _ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - step * gx, step)
    end
end
function _updatebatchβ!(o::StatLearn{AdaGrad}, g::AVec, x::AMat, y::AVec, ŷ::AVec, γ)
    alg = o.algorithm
    ηγ = o.η * γ
    w = 1 / o.weight.nups  # for updating denominators
    if o.intercept
        gbar = mean(g)
        alg.g0 = smooth(alg.g0, gbar * gbar, w)
        step = ηγ / (sqrt(alg.g0) + _ϵ)
        setβ0!(o, step, gbar)
    end
    for j in eachindex(o.β)
        gx = batch_g(sub(x, :, j), g)
        alg.g[j] = smooth(alg.g[j], gx * gx, w)
        step = ηγ / (sqrt(alg.g[j]) + _ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - step * gx, step)
    end
end


#--------------------------------------------------------------------------# AdaGrad2
type AdaGrad2 <: Algorithm
    g0::Float64
    g::VecF
    AdaGrad2() = new()
    AdaGrad2(p::Integer, alg::AdaGrad2) = new(0.0, zeros(p))
end
function _updateβ!(o::StatLearn{AdaGrad2}, g, x, y, ŷ, γ)
    alg = o.algorithm
    ηγ = o.η * γ
    if o.intercept
        alg.g0 += g * g
        alg.g0 = smooth(alg.g0, g * g, γ)
        step = ηγ / (sqrt(alg.g0) + _ϵ)
        setβ0!(o, step, g)
    end
    for j in 1:length(o.β)
        gx = g * x[j]
        alg.g[j] = smooth(alg.g[j], gx * gx, γ)
        step = ηγ / (sqrt(alg.g[j]) + _ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - step * gx, step)
    end
end
function _updatebatchβ!(o::StatLearn{AdaGrad2}, g::AVec, x::AMat, y::AVec, ŷ::AVec, γ)
    alg = o.algorithm
    ηγ = o.η * γ
    if o.intercept
        gbar = mean(g)
        alg.g0 = smooth(alg.g0, gbar * gbar, γ)
        step = ηγ / (sqrt(alg.g0) + _ϵ)
        setβ0!(o, step, gbar)
    end
    for j in eachindex(o.β)
        gx = batch_g(sub(x, :, j), g)
        alg.g[j] = smooth(alg.g[j], gx * gx, γ)
        step = ηγ / (sqrt(alg.g[j]) + _ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - step * gx, step)
    end
end


#--------------------------------------------------------------------------# AdaDelta
# Ignores weight.  `step` needs special attention here. See paper:
# http://arxiv.org/abs/1212.5701
type AdaDelta <: Algorithm
    g0::Float64
    g::VecF
    Δ0::Float64
    Δ::VecF
    ρ::Float64
    ϵ::Float64
    AdaDelta(ρ::Real = .05, ϵ::Real = .01) = new(0.0, zeros(1), 0.0, zeros(1), ρ, ϵ)
    AdaDelta(p::Integer, alg::AdaDelta) = new(0.0, zeros(p), 0.0, zeros(p), alg.ρ, alg.ϵ)
end
function _updateβ!(o::StatLearn{AdaDelta}, g, x, y, ŷ, γ)
    alg = o.algorithm
    if o.intercept
        alg.g0 = smooth(alg.g0, g * g, alg.ρ)
        step = sqrt((alg.Δ0 + alg.ϵ) / (alg.g0 + alg.ϵ))
        Δ = step * g
        o.β0 -= o.η * Δ
        alg.Δ0 = smooth(alg.Δ0, Δ * Δ, alg.ρ)
    end
    for j in eachindex(o.β)
        gx = g * x[j]
        alg.g[j] = smooth(alg.g[j], gx * gx, alg.ρ)
        step = sqrt((alg.Δ0 + alg.ϵ) / (alg.g[j] + alg.ϵ))
        Δ = step * gx
        o.β[j] = prox(o.penalty, o.β[j] - o.η * Δ, o.η * step)
        alg.Δ[j] = smooth(alg.Δ[j], Δ * Δ, alg.ρ)
    end
end
function _updatebatchβ!(o::StatLearn{AdaDelta}, g::AVec, x::AMat, y::AVec, ŷ::AVec, γ)
    alg = o.algorithm
    if o.intercept
        gbar = mean(g)
        alg.g0 = smooth(alg.g0, gbar * gbar, alg.ρ)
        step = sqrt((alg.Δ0 + alg.ϵ) / (alg.g0 + alg.ϵ))
        Δ = step* gbar
        o.β0 -= o.η * Δ
        alg.Δ0 = smooth(alg.Δ0, Δ * Δ, alg.ρ)
    end
    for j in eachindex(o.β)
        gx = batch_g(sub(x, :, j), g)
        alg.g[j] = smooth(alg.g[j], gx * gx, alg.ρ)
        step = sqrt((alg.Δ0 + alg.ϵ) / (alg.g[j] + alg.ϵ))
        Δ = step * gx
        o.β[j] = prox(o.penalty, o.β[j] - o.η * Δ, o.η * step)
        alg.Δ[j] = smooth(alg.Δ[j], Δ * Δ, alg.ρ)
    end
end


#------------------------------------------------------------------------------# ADAM
type ADAM <: Algorithm
    β1::Float64
    β2::Float64
    m0::Float64
    m::VecF
    v0::Float64
    v::VecF
    ADAM(beta1 = .1, beta2 = .001) = new(beta1, beta2)
    ADAM(p::Integer, alg::ADAM) = new(alg.β1, alg.β2, _ϵ, fill(_ϵ, p), _ϵ, fill(_ϵ, p))
end
function _updateβ!(o::StatLearn{ADAM}, g, x, y, ŷ, γ)
    alg = o.algorithm
    β1 = alg.β1
    β2 = alg.β2
    nups = o.weight.nups
    bias = (1. - β1 ^ (.5 * nups)) / (1. - β1 ^ nups)
    ηγ = o.η * γ
    if o.intercept
        alg.m0 = (1. - β1) * alg.m0 + β1 * g
        alg.v0 = (1. - β2) * alg.v0 + β2 * g * g
        step = ηγ * bias / (sqrt(alg.v0) + _ϵ)
        o.β0 -= step * alg.m0
    end
    for j in eachindex(o.β)
        gx = g * x[j]
        alg.m[j] = (1. - β1) * alg.m[j] + β1 * gx
        alg.v[j] = (1. - β2) * alg.v[j] + β2 * gx * gx
        step = ηγ * bias / (sqrt(alg.v[j]) + _ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - step * alg.m[j], step)
    end
end
function _updatebatchβ!(o::StatLearn{ADAM}, g, x, y, ŷ, γ)
    n = length(g)
    alg = o.algorithm
    β1 = alg.β1
    β2 = alg.β2
    nups = o.weight.nups
    bias = (1. - β1 ^ (.5 * nups)) / (1. - β1 ^ nups)
    ηγ = o.η * γ
    if o.intercept
        gbar = mean(g)
        alg.m0 = (1. - β1) * alg.m0 + β1 * gbar
        alg.v0 = (1. - β2) * alg.v0 + β2 * gbar * gbar
        step = ηγ * bias / (sqrt(alg.v0) + _ϵ)
        o.β0 -= step * alg.m0
    end
    for j in eachindex(o.β)
        gx = batch_g(sub(x, :, j), g)
        alg.m[j] = (1. - β1) * alg.m[j] + β1 * gx
        alg.v[j] = (1. - β2) * alg.v[j] + β2 * gx * gx
        step = ηγ * bias / (sqrt(alg.v[j]) + _ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - step * alg.m[j], step)
    end
end


#--------------------------------------------------------------------------# RDA
# TODO: reparameterize to allow weights
type RDA <: Algorithm
    g0::Float64
    g::VecF
    gbar0::Float64
    gbar::VecF
    RDA() = new()
    RDA(p::Integer, alg::RDA) = new(_ϵ, fill(_ϵ, p), _ϵ, fill(_ϵ, p))
end
function _updateβ!(o::StatLearn{RDA}, g, x, y, ŷ, γ)
    w = 1 / o.weight.nups
    alg = o.algorithm
    if o.intercept
        alg.g0 += g * g
        alg.gbar0 = smooth(alg.gbar0, g, w)
        o.β0 = -o.weight.nups * o.η * alg.gbar0 / sqrt(alg.g0)
    end
    for j in 1:length(o.β)
        gx = g * x[j]
        alg.g[j] += gx * gx
        alg.gbar[j] = smooth(alg.gbar[j], gx, w)
        rda_update!(o, j)
    end
end
function _updatebatchβ!(o::StatLearn{RDA}, g, x, y, ŷ, γ)
    n = length(g)
    w = 1 / o.weight.nups
    alg = o.algorithm
    if o.intercept
        ḡ = mean(g)
        alg.g0 += ḡ * ḡ
        alg.gbar0 = smooth(alg.gbar0, ḡ, w)
        o.β0 = -o.weight.nups * o.η * alg.gbar0 / sqrt(alg.g0)
    end
    for j in 1:length(o.β)
        gx = 0.0
        for i in 1:n
            gx = g[i] * x[i, j]
        end
        gx /= n
        alg.g[j] += gx * gx
        alg.gbar[j] = smooth(alg.gbar[j], gx, w)
        rda_update!(o, j)
    end
end

# NoPenalty
function rda_update!{M<:ModelDefinition}(o::StatLearn{RDA, M, NoPenalty}, j::Int)
    o.β[j] = -rda_γ(o, j) * o.algorithm.gbar[j]
end
# RidgePenalty
function rda_update!{M<:ModelDefinition}(o::StatLearn{RDA, M, RidgePenalty}, j::Int)
    o.algorithm.gbar[j] += (1 / o.weight.nups) * o.penalty.λ * o.β[j]  # add in penalty gradient
    o.β[j] = -rda_γ(o,j) * o.algorithm.gbar[j]
end
# LassoPenalty (http://www.magicbroom.info/Papers/DuchiHaSi10.pdf)
function rda_update!{M<:ModelDefinition}(o::StatLearn{RDA, M, LassoPenalty}, j::Int)
    ḡ = o.algorithm.gbar[j]
    o.β[j] = sign(-ḡ) * rda_γ(o, j) * max(0.0, abs(ḡ) - o.penalty.λ)
end
# ElasticNetPenalty
function rda_update!{M<:ModelDefinition}(o::StatLearn{RDA, M, ElasticNetPenalty}, j::Int)
    o.algorithm.gbar[j] += (1 / o.weight.nups) * o.penalty.λ * (1 - o.penalty.α) * o.β[j]
    ḡ = o.algorithm.gbar[j]
    o.β[j] = sign(-ḡ) * rda_γ(o, j) * max(0.0, abs(ḡ) - o.penalty.λ * o.penalty.α)
end
# adaptive weight for element j
rda_γ(o::StatLearn{RDA}, j::Int) = o.weight.nups * o.η / sqrt(o.algorithm.g[j])


#----------------------------------------------------------------------------# MMGrad
type MMGrad <: Algorithm
    h0::Float64
    h::VecF  # Diagonal elements of H = -d^2 h(β)
    ϵ::Float64
    MMGrad(eps::Real = 1e-4) = new(0.0, zeros(1), eps)
    MMGrad(p::Integer, alg::MMGrad) = new(0.0, zeros(p), alg.ϵ)
end
function _updateβ!(o::StatLearn{MMGrad}, g, x, y, ŷ, γ)
    ηγ = o.η * γ
    alg = o.algorithm
    denom = sumabs(x) + o.intercept + ndims(o) * alg.ϵ
    if o.intercept
        alg.h0 = smooth(alg.h0, d2h(o, 1.0, y, ŷ, 1.0 / denom), γ)
        step = ηγ / (alg.h0 + alg.ϵ)
        o.β0 -= step * g
    end
    @inbounds for j in 1:length(o.β)
        xj = x[j]
        alg.h[j] = smooth(alg.h[j], d2h(o, xj, y, ŷ, abs(xj) / denom + alg.ϵ), γ)
        step = ηγ / (alg.h[j] + alg.ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - step * g * xj, step)
    end
end
function _updatebatchβ!(o::StatLearn{MMGrad}, g, x, y, ŷ, γ)
    n = length(g)
    ηγ = o.η * γ
    alg = o.algorithm
    denom = sumabs(x, 2) + o.intercept + ndims(o) * alg.ϵ
    if o.intercept
        v = 0.0
        for i in 1:n
            v += d2h(o, 1.0, y[i], ŷ[i], 1.0 / denom[i])
        end
        alg.h0 = smooth(alg.h0, v / n, γ)
        step = ηγ / (alg.h0 + alg.ϵ)
        o.β0 -= step * mean(g)
    end
    for j in 1:length(o.β)
        v = 0.0
        u = 0.0
        for i in 1:n
            xij = x[i, j]
            v += d2h(o, xij, y[i], ŷ[i], abs(xij) / denom[i] + alg.ϵ)
            u += g[i] * xij
        end
        alg.h[j] = smooth(alg.h[j], v / n, γ)
        step = ηγ / (alg.h[j] + alg.ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - step * u / n, step)
    end
end

# second (partial) derivative of majorizing function, h(β_t), based on α
# α = (abs(xj) + _ϵ) / (sumabs(xj) + ndims(o) * _ϵ)
d2h(o::StatLearn{MMGrad, L2Regression}, xj, y, ŷ, α)          = xj * xj / α
d2h(o::StatLearn{MMGrad, L1Regression}, xj, y, ŷ, α)          = xj * xj / (α * abs(y - ŷ))
d2h(o::StatLearn{MMGrad, LogisticRegression}, xj, y, ŷ, α)    = xj * xj / α * (ŷ * (1 - ŷ))
d2h(o::StatLearn{MMGrad, PoissonRegression}, xj, y, ŷ, α)     = xj * xj * ŷ / α
# MMGrad only derived for canonical link GLMs (for now).
d2h(o::StatLearn{MMGrad}, xj, αd, y, ŷ) = 1.0





for alg in [:SGD, :AdaGrad, :AdaGrad2, :AdaDelta, :RDA, :MMGrad, :ADAM]
    eval(parse("""Base.show(io::IO, o::$alg) = print(io, "$alg")"""))
end
