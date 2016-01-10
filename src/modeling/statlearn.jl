#---------------------------------------------------------------------# ModelDef
abstract ModelDef
abstract GLMDef <: ModelDef

immutable L2Regression <: GLMDef end
immutable L1Regression <: ModelDef end
immutable LogisticRegression <: GLMDef end
immutable PoissonRegression <: GLMDef end
immutable QuantileRegression <: ModelDef
    τ::Float64
    function QuantileRegression(τ::Real = .5)
        @assert 0 < τ < 1
        new(Float64(τ))
    end
end
immutable SVMLike <: ModelDef end
immutable HuberRegression <: ModelDef
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
function StatsBase.predict{T<:Real}(o::ModelDef, x::AMat{T}, β0::Float64, β::VecF)
    [predict(o, row(x, i), β0, β) for i in 1:size(x, 1)]
end


# y and η are Vectors
loss(::L2Regression, y, η) = mean(abs2(y - η))
loss(::L1Regression, y, η) = mean(abs(y - η))
loss(::LogisticRegression, y, η) = mean(-y .* η + log(1.0 + exp(η)))
loss(::PoissonRegression, y, η) = mean(-y .* η + exp(η))
loss(m::QuantileRegression, y, η) =
    mean([(y[i] - η[i]) * (m.τ - Float64(y[i] < η[i])) for i in 1:length(y)])
loss(m::SVMLike, y, η) =
    mean([max(0.0, 1.0 - y[i] * η[i]) for i in 1:length(y)])
function loss(m::HuberRegression, y, η)
    mean([
        abs(y[i]-η[i]) < m.δ ?
        0.5 * (y[i]-η[i])^2 :
        m.δ * (abs(y[i]-η[i]) - 0.5 * m.δ)
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


immutable SGD <: Algorithm
    SGD() = new()
    SGD(p::Integer) = new()
end
type AdaGrad <: Algorithm
    g0::Float64
    g::VecF
    AdaGrad() = new()
    AdaGrad(p::Integer) = new(_ϵ, fill(_ϵ, p))
end
type AdaDelta <: Algorithm
    g0::Float64
    g::VecF
    Δ0::Float64
    Δ::VecF
    ρ::Float64
    AdaDelta() = new()
    AdaDelta(p::Integer) = new(_ϵ, fill(_ϵ, p), _ϵ, fill(_ϵ, p), 0.001)
end
type RDA <: Algorithm
    g0::Float64
    g::VecF
    gbar0::Float64
    gbar::VecF
    RDA() = new()
    RDA(p::Integer) = new(_ϵ, fill(_ϵ, p), _ϵ, fill(_ϵ, p))
end
type MMGrad <: Algorithm
    g0::Float64
    g::VecF
    MMGrad() = new()
    MMGrad(p::Integer) = new(_ϵ, fill(_ϵ, p))
end
type AdaMMGrad <: Algorithm
    g0::Float64
    g::VecF
    AdaMMGrad() = new()
    AdaMMGrad(p::Integer) = new(_ϵ, fill(_ϵ, p))
end
for alg in [:SGD, :AdaGrad, :AdaDelta, :RDA, :MMGrad, :AdaMMGrad]
    eval(parse("""Base.show(io::IO, o::$alg) = print(io, "$alg")"""))
end


#--------------------------------------------------------------------# StatLearn
"""
### Online Statistical Learning
- `StatLearn(p)`
- `StatLearn(x, y)`
- `StatLearn(x, y, b)`

The model is defined by:

#### `ModelDef`

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
    - Perceptron with `NoPenalty`. SVM with `L2Penalty`.
- `HuberRegression(δ)`
    - Robust Huber loss

#### `Penalty`
- `NoPenalty()`
    - No penalty.  Default.
- `L2Penalty(λ)`
    - Ridge regularization
- `L1Penalty(λ)`
    - LASSO regularization
- `ElasticNetPenalty(λ, α)`
    - Ridge/LASSO weighted average.  `α = 0` is Ridge, `α = 1` is LASSO.

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
- `AdaMMGrad()`
    - Experimental adaptive online MM gradient method.  Ignores `Weight`.


### Example:
`StatLearn(x, y, 10, LearningRate(.7), RDA(), SVMLike(), L2Penalty(.1))`
"""
type StatLearn{A<:Algorithm, M<:ModelDef, P<:Penalty, W<:Weight} <: OnlineStat
    β0::Float64     # intercept
    β::VecF         # coefficients
    intercept::Bool # should β0 be estimated?
    algorithm::A    # determines how updates work
    model::M        # model definition
    η::Float64      # constant part of learning rate
    penalty::P      # type of penalty
    weight::W       # Weight, may not get used, depending on algorithm
    n::Int          # nobs
    nup::Int        # n updates
end
function _StatLearn(p::Integer, wgt::Weight = LearningRate();
        model::ModelDef = L2Regression(),
        η::Real = 1.0,
        penalty::Penalty = NoPenalty(),
        algorithm::Algorithm = SGD(),
        intercept::Bool = true
    )
    o = StatLearn(
        0.0, zeros(p), intercept, algorithm, model,
        Float64(η), penalty, wgt, 0, 0
    )
    o.algorithm = typeof(o.algorithm)(p)
    o
end
# function _StatLearn(x::AMat, y::AVec, wgt::Weight = LearningRate(); kw...)
#     o = _StatLearn(size(x, 2), wgt; kw...)
#     fit!(o, x, y)
#     o
# end
# function _StatLearn(x::AMat, y::AVec, b::Integer, wgt::Weight = LearningRate(); kw...)
#     o = _StatLearn(size(x, 2), wgt; kw...)
#     fit!(o, x, y, b)
#     o
# end
function StatLearn(p::Integer, args...; kw...)
    wgt = LearningRate()
    mod = L1Regression()
    alg = SGD()
    pen = NoPenalty()
    for arg in args
        T = typeof(arg)
        if T <: Weight
            wgt = arg
        elseif T <: ModelDef
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
value(o::StatLearn) = o.intercept ? vcat(o.β0, o.β) : o.β
function Base.show(io::IO, o::StatLearn)
    printheader(io, "StatLearn")
    print_item(io, "value", coef(o))
    print_item(io, "model", o.model)
    print_item(io, "penalty", o.penalty)
    print_item(io, "nobs", nobs(o))
end
function fit!{T<:Real}(o::StatLearn, x::AVec{T}, y::Real)
    length(x) == length(o.β) || error("x is incorrect length")
    ŷ = predict(o, x)
    g = deriv(o.model, y, ŷ)
    _updateβ!(o, g, x, y, ŷ)
end
function fitbatch!{T<:Real, S<:Real}(o::StatLearn, x::AMat{T}, y::AVec{S})
    size(x, 2) == length(o.β) || error("x has incorrect number of columns")
    ŷ = predict(o, x)
    g = [deriv(o.model, y[i], ŷ[i]) for i in 1:size(x, 1)]
    _updatebatchβ!(o, g, x, y, ŷ)
end
setβ0!(o::StatLearn, γ, g) = (o.β0 = subgrad(o.β0, γ, g))
loss(o::StatLearn, x::AMat, y::AVec) = loss(o.model, y, o.β0 + x * o.β)




#==============================================================================#
#                                                           Updates by Algorithm
#==============================================================================#
#--------------------------------------------------------------------------# SGD
function _updateβ!(o::StatLearn{SGD}, g, x, y, ŷ)
    γ = weight!(o, 1)
    γ *= o.η
    if o.intercept
        o.β0 -= γ * g
    end
    for j in 1:length(o.β)
        @inbounds o.β[j] = prox(o.penalty, o.β[j] - γ * g * x[j], γ)
    end
end
function _updatebatchβ!(o::StatLearn{SGD}, g::AVec, x::AMat, y::AVec, ŷ::AVec)
    n2 = length(y)
    γ = o.η * weight!(o, n2)
    if o.intercept
        o.β -= γ * mean(g)
    end
    for j in 1:length(o.β)
        gj = 0.0
        for i in 1:n2
            gj += g[i] * x[i, j]
        end
        gj /= n2
        o.β[j] = prox(o.penalty, o.β[j] - γ * gj, γ)
    end
end




#----------------------------------------------------------------------# AdaGrad
function _updateβ!(o::StatLearn{AdaGrad}, g, x, y, ŷ)
    n_and_nup!(o, 1)
    if o.intercept
        o.algorithm.g0 += g * g
        setβ0!(o, o.η / sqrt(o.algorithm.g0), g)
    end
    @inbounds for j in 1:length(o.β)
        gx = g * x[j]
        o.algorithm.g[j] += gx * gx
        γ = o.η / sqrt(o.algorithm.g[j])
        o.β[j] = prox(o.penalty, o.β[j] - γ * gx, γ)
    end
end
function _updatebatchβ!(o::StatLearn{AdaGrad}, g::AVec, x::AMat, y::AVec, ŷ::AVec)
    n_and_nup!(o, length(y))
    if o.intercept
        ḡ = mean(g)
        o.algorithm.g0 += ḡ * ḡ
        setβ0!(o, o.η / sqrt(o.algorithm.g0), ḡ)
    end
    n = length(g)
    @inbounds for j in 1:length(o.β)
        gx = 0.0
        for i in 1:n
            gx += g[i] * x[i, j]
        end
        gx /= n
        o.algorithm.g[j] += gx * gx
        γ = o.η / sqrt(o.algorithm.g[j])
        o.β[j] = prox(o.penalty, o.β[j] - γ * gx, γ)
    end
end


#----------------------------------------------------------------------# AdaDelta
function _updateβ!(o::StatLearn{AdaDelta}, g, x, y, ŷ)
    n_and_nup!(o, 1)
    if o.intercept
        o.algorithm.g0 = smooth(o.algorithm.g0, g * g, o.algorithm.ρ)
        Δ = sqrt(o.algorithm.Δ0 / o.algorithm.g0) * g
        o.β0 -= Δ
        o.algorithm.Δ0 = smooth(o.algorithm.Δ0, Δ * Δ, o.algorithm.ρ)
    end
    @inbounds for j in 1:length(o.β)
        gx = g * x[j]
        o.algorithm.g[j] = smooth(o.algorithm.g[j], gx * gx, o.algorithm.ρ)
        γ = sqrt(o.algorithm.Δ[j] / o.algorithm.g[j])
        Δ = γ * gx
        o.β[j] = prox(o.penalty, o.β[j] - Δ, γ)
        o.algorithm.Δ[j] = smooth(o.algorithm.Δ[j], Δ * Δ, o.algorithm.ρ)
    end
end
function _updatebatchβ!(o::StatLearn{AdaDelta}, g::AVec, x::AMat, y::AVec, ŷ::AVec)
    n_and_nup!(o, length(y))
    if o.intercept
        ḡ = mean(g)
        o.algorithm.g0 = smooth(o.algorithm.g0, ḡ * ḡ, o.algorithm.ρ)
        Δ = sqrt(o.algorithm.Δ0 / o.algorithm.g0) * ḡ
        o.β0 -= Δ
        o.algorithm.Δ0 = smooth(o.algorithm.Δ0, Δ * Δ, o.algorithm.ρ)
    end
    n = length(g)
    @inbounds for j in 1:length(o.β)
        gx = 0.0
        for i in 1:n
            gx += g[i] * x[i, j]
        end
        gx /= n
        o.algorithm.g[j] = smooth(o.algorithm.g[j], gx * gx, o.algorithm.ρ)
        γ = sqrt(o.algorithm.Δ[j] / o.algorithm.g[j])
        Δ = γ * gx
        o.β[j] = prox(o.penalty, o.β[j] - γ * gx, γ)
        o.algorithm.Δ[j] = smooth(o.algorithm.Δ[j], Δ * Δ, o.algorithm.ρ)
    end
end


#--------------------------------------------------------------------------# RDA
function _updateβ!(o::StatLearn{RDA}, g, x, y, ŷ)
    n_and_nup!(o, 1)
    w = 1 / o.nup
    if o.intercept
        o.algorithm.g0 += g * g
        o.algorithm.gbar0 = smooth(o.algorithm.gbar0, g, w)
        o.β0 = -o.nup * o.η * o.algorithm.gbar0 / sqrt(o.algorithm.g0)
    end
    for j in 1:length(o.β)
        gx = g * x[j]
        o.algorithm.g[j] += gx * gx
        o.algorithm.gbar[j] = smooth(o.algorithm.gbar[j], gx, w)
        rda_update!(o, j)
    end
end
function _updatebatchβ!(o::StatLearn{RDA}, g, x, y, ŷ)
    n = length(g)
    n_and_nup!(o, n)
    w = 1 / o.nup
    if o.intercept
        ḡ = mean(g)
        o.algorithm.g0 += ḡ * ḡ
        o.algorithm.gbar0 = smooth(o.algorithm.gbar0, ḡ, w)
        o.β0 = -o.nup * o.η * o.algorithm.gbar0 / sqrt(o.algorithm.g0)
    end
    for j in 1:length(o.β)
        gx = 0.0
        for i in 1:n
            gx = g[i] * x[i, j]
        end
        gx /= n
        o.algorithm.g[j] += gx * gx
        o.algorithm.gbar[j] = smooth(o.algorithm.gbar[j], gx, w)
        rda_update!(o, j)
    end
end

# NoPenalty
function rda_update!{M<:ModelDef}(o::StatLearn{RDA, M, NoPenalty}, j::Int)
    o.β[j] = -rda_γ(o, j) * o.algorithm.gbar[j]
end
# L2Penalty
function rda_update!{M<:ModelDef}(o::StatLearn{RDA, M, L2Penalty}, j::Int)
    o.algorithm.gbar[j] += (1 / o.nup) * o.penalty.λ * o.β[j]  # add in penalty gradient
    o.β[j] = -rda_γ(o,j) * o.algorithm.gbar[j]
end
# L1Penalty (http://www.magicbroom.info/Papers/DuchiHaSi10.pdf)
function rda_update!{M<:ModelDef}(o::StatLearn{RDA, M, L1Penalty}, j::Int)
    ḡ = o.algorithm.gbar[j]
    o.β[j] = sign(-ḡ) * rda_γ(o, j) * max(0.0, abs(ḡ) - o.penalty.λ)
end
# ElasticNetPenalty
function rda_update!{M<:ModelDef}(o::StatLearn{RDA, M, ElasticNetPenalty}, j::Int)
    o.algorithm.gbar[j] += (1 / o.nup) * o.penalty.λ * (1 - o.penalty.α) * o.β[j]
    ḡ = o.algorithm.gbar[j]
    o.β[j] = sign(-ḡ) * rda_γ(o, j) * max(0.0, abs(ḡ) - o.penalty.λ * o.penalty.α)
end
# adaptive weight for element j
rda_γ(o::StatLearn{RDA}, j::Int) = o.nup * o.η / sqrt(o.algorithm.g[j])


#-----------------------------------------------------------------------# MMGrad
_α(o::StatLearn, xj, x) = (abs(xj) + _ϵ) / (sumabs(x) + o.intercept + _ϵ)
function mmsuff{A<:Algorithm}(o::StatLearn{A, L2Regression}, xj, x, y, ŷ)
    xj^2 / _α(o, xj, x)
end
function mmsuff{A<:Algorithm}(o::StatLearn{A, L1Regression}, xj, x, y, ŷ)
    xj^2 / (_α(o, xj, x) * abs(y - ŷ))
end
function mmsuff{A<:Algorithm}(o::StatLearn{A, LogisticRegression}, xj, x, y, ŷ)
    xj^2 / _α(o, xj, x) * (ŷ * (1 - ŷ))
end
function mmsuff{A<:Algorithm}(o::StatLearn{A, PoissonRegression}, xj, x, y, ŷ)
    xj^2 * ŷ / _α(o, xj, x)
end
function mmsuff{A<:Algorithm}(o::StatLearn{A, QuantileRegression}, xj, x, y, ŷ)
    xj^2 / (_α(o, xj, x) * abs(y - ŷ))
end

# TODO:
function mmsuff{A<:Algorithm}(o::StatLearn{A, SVMLike}, xj, x, y, ŷ)
    1.0
end
function mmsuff{A<:Algorithm}(o::StatLearn{A, HuberRegression}, xj, x, y, ŷ)
    1.0
end


function _updateβ!(o::StatLearn{MMGrad}, g, x, y, ŷ)
    γ = weight!(o, 1)
    if o.intercept
        o.algorithm.g0 = smooth(o.algorithm.g0, mmsuff(o, 1.0, x, y, ŷ), γ)
        setβ0!(o, γ, g / o.algorithm.g0)
    end
    for j in 1:length(o.β)
        o.algorithm.g[j] = smooth(o.algorithm.g[j], mmsuff(o, x[j], x, y, ŷ), γ)
        @inbounds o.β[j] = prox(o.penalty, o.β[j] - γ * g * x[j] / o.algorithm.g[j], γ)
    end
end
function _updatebatchβ!(o::StatLearn{MMGrad}, g, x, y, ŷ)
    n = length(g)
    γ = weight!(o, n)
    if o.intercept
        v = 0.0
        for i in 1:n
            v += mmsuff(o, 1.0, row(x, i), y[i], ŷ[i])
        end
        o.algorithm.g0 = smooth(o.algorithm.g0, v / n, γ)
        setβ0!(o, γ, mean(g) / o.algorithm.g0)
    end
    for j in 1:length(o.β)
        v = 0.0
        u = 0.0
        for i in 1:n
            xij = x[i, j]
            v += mmsuff(o, xij, row(x, i), y[i], ŷ[i])
            u += g[i] * xij
        end
        o.algorithm.g[j] = smooth(o.algorithm.g[j], v / n, γ)
        @inbounds o.β[j] = prox(o.penalty, o.β[j] - γ * u / n / o.algorithm.g[j], γ)
    end
end


#--------------------------------------------------------------------# AdaMMGrad
function _updateβ!(o::StatLearn{AdaMMGrad}, g, x, y, ŷ)
    n_and_nup!(o, 1)
    if o.intercept
        o.algorithm.g0 += mmsuff(o, 1.0, x, y, ŷ)
        setβ0!(o, o.η / sqrt(o.algorithm.g0), g)
    end
    for j in 1:length(o.β)
        o.algorithm.g[j] += mmsuff(o, x[j], x, y, ŷ)
        γ = o.η / sqrt(o.algorithm.g[j])
        o.β[j] = prox(o.penalty, o.β[j] - o.η * γ * g * x[j], γ)
    end
end
function _updatebatchβ!(o::StatLearn{AdaMMGrad}, g, x, y, ŷ)
    n = length(g)
    n_and_nup!(o, n)
    if o.intercept
        v = 0.0
        for i in 1:n
            v += mmsuff(o, 1.0, row(x,i), y[i], ŷ[i])
        end
        o.algorithm.g0 += v / n
        setβ0!(o, o.η / sqrt(o.algorithm.g0), mean(g))
    end
    for j in 1:length(o.β)
        v = 0.0
        u = 0.0
        for i in 1:n
            xij = x[i, j]
            v += mmsuff(o, xij, row(x, i), y[i], ŷ[i])
            u += g[i] * xij
        end
        o.algorithm.g[j] += v / n
        γ = o.η / sqrt(o.algorithm.g[j])
        o.β[j] = prox(o.penalty, o.β[j] - o.η * γ * u / n, γ)
    end
end
