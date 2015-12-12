#---------------------------------------------------------------------# ModelDef
abstract ModelDef
abstract GLMDef <: ModelDef

immutable L2Regression <: GLMDef end
immutable L1Regression <: GLMDef end
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
        abs(y[i]-η[i]) < m.δ ? 0.5 * (y[i]-η[i])^2 : m.δ * (abs(y[i]-η[i]) - 0.5 * m.δ)
        for i in 1:length(y)
        ])
end



deriv(o::GLMDef, y::Real, ŷ::Real) = ŷ - y  # Canonical link GLMs
deriv(m::QuantileRegression, y::Real, ŷ::Real) = Float64(y < ŷ) - m.τ
deriv(m::SVMLike, y::Real, ŷ::Real) = y * ŷ < 1 ? -y : 0.0
deriv(m::HuberRegression, y::Real, ŷ::Real) = abs(y - ŷ) <= m.δ ? ŷ - y : m.δ * sign(ŷ - y)



#--------------------------------------------------------------------# Algorithm
abstract Algorithm

immutable SGD <: Algorithm end
immutable AdaGrad <: Algorithm end
immutable RDA <: Algorithm end
immutable MMGrad <: Algorithm end
immutable AdaMMGrad <: Algorithm end

for alg in [:SGD, :AdaGrad, :RDA, :MMGrad, :AdaMMGrad]
    eval(parse(
    """
    Base.show(io::IO, o::$alg) = print(io, "$alg")
    """
    ))
end
# Base.show(io::IO, o::SGD) = print(io, "SGD")


#--------------------------------------------------------------------# StatLearn
type StatLearn{A<:Algorithm, M<:ModelDef, P<:Penalty, W<:Weight} <: OnlineStat
    β0::Float64     # intercept
    β::VecF         # coefficients
    suff0::Float64 # "sufficient statistic" for β0
    suff::VecF     # "sufficient statistics" for β
    intercept::Bool # should β0 be estimated?
    algorithm::A    # determines how updates work
    model::M        # model definition
    η::Float64      # constant part of learning rate
    λ::Float64      # regularization parameter
    penalty::P      # type of penalty
    weight::W       # Weight, may not get used, depending on algorithm
    n::Int          # nobs
    nup::Int        # n updates
end
function StatLearn(p::Integer, wgt::Weight = LearningRate();
        model::ModelDef = L2Regression(),
        η::Real = 1.0,
        λ::Real = 0.0,
        penalty::Penalty = NoPenalty(),
        algorithm::Algorithm = SGD(),
        intercept::Bool = true
    )
    StatLearn(
        0.0, zeros(p), _ϵ, fill(_ϵ, p), intercept, algorithm,
        model, Float64(η), Float64(λ), penalty, wgt, 0, 0
    )
end
function StatLearn(x::AMat, y::AVec, wgt::Weight = LearningRate(); kw...)
    o = StatLearn(size(x, 2), wgt; kw...)
    fit!(o, x, y)
    o
end
function StatLearn(x::AMat, y::AVec, b::Integer, wgt::Weight = LearningRate(); kw...)
    o = StatLearn(size(x, 2), wgt; kw...)
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
    γ = o.η * weight!(o, 1)
    ŷ = predict(o, x)
    g = deriv(o.model, y, ŷ)
    _updateβ!(o, γ, g, x, y, ŷ)
end
function fitbatch!{T<:Real, S<:Real}(o::StatLearn, x::AMat{T}, y::AVec{S})
    n2 = length(y)
    γ = o.η * weight!(o, n2) / n2
    ŷ = predict(o, x)
    g = [deriv(o.model, y[i], ŷ[i]) for i in 1:n2]
    _updatebatchβ!(o, γ, g, x, y, ŷ)
end
setβ0!(o::StatLearn, γ, g) = (o.β0 = subgrad(o.β0, γ, g))


loss(o::StatLearn, x::AMat, y::AVec) = loss(o.model, y, o.β0 + x * o.β)




#==============================================================================#
#                                                           Updates by Algorithm
#==============================================================================#
#--------------------------------------------------------------------------# SGD
function _updateβ!(o::StatLearn{SGD}, γ, g, x, y, ŷ)
    o.intercept && setβ0!(o, γ, g)
    for j in 1:length(o.β)
        @inbounds o.β[j] = prox(o.penalty, o.λ, o.β[j] - γ * g * x[j], γ)
    end
end
function _updatebatchβ!(o::StatLearn{SGD}, γ, g::AVec, x::AMat, y::AVec, ŷ::AVec)
    for i in 1:length(g)
        gi = g[i]
        o.intercept && setβ0!(o, γ, gi)
        for j in 1:length(o.β)
            @inbounds o.β[j] = prox(o.penalty, o.λ, o.β[j] - γ * gi * x[i, j], γ)
        end
    end
end


#----------------------------------------------------------------------# AdaGrad
# ignores Weight
function _updateβ!(o::StatLearn{AdaGrad}, γ, g, x, y, ŷ)
    if o.intercept
        o.suff0 += g * g
        setβ0!(o, o.η / sqrt(o.suff0), g)
    end
    for j in 1:length(o.β)
        gx = g * x[j]
        o.suff[j] += gx * gx
        γ = o.η / sqrt(o.suff[j])
        @inbounds o.β[j] = prox(o.penalty, o.λ, o.β[j] - γ * gx, γ)
    end
end
function _updatebatchβ!(o::StatLearn{AdaGrad}, γ, g::AVec, x::AMat, y::AVec, ŷ::AVec)
    if o.intercept
        ḡ = mean(g)
        o.suff0 += ḡ * ḡ
        setβ0!(o, o.η / o.suff0, ḡ)
    end
    n = length(g)
    for j in 1:length(o.β)
        gx = 0.0
        for i in 1:n
            gx += g[i] * x[i, j]
        end
        gx /= n
        o.suff[j] += gx * gx
        γ = o.η / sqrt(o.suff[j])
        o.β[j] = prox(o.penalty, o.λ, o.β[j] - γ * gx, γ)
    end
end


#--------------------------------------------------------------------------# RDA
# ignores Weight
# - A hack to fit RDA into the same scheme as everything else:
# o.suff[1] is average gradient for intercept
# o.suff[2j] is squared gradient for element j
# o.suff[2j + 1] is average gradient for element j
function _updateβ!(o::StatLearn{RDA}, γ, g, x, y, ŷ)
    if o.nup == 1
        o.suff = fill(o.suff0, length(x) * 2 + 1)
    end
    w = 1 / o.nup
    if o.intercept
        o.suff0 += g * g
        o.suff[1] = smooth(o.suff[1], g, w)
        o.β0 = - o.nup * o.η * o.suff[1] / sqrt(o.suff0)
    end
    for j in 1:length(o.β)
        gx = g * x[j]
        o.suff[2j] += gx * gx
        o.suff[2j + 1] = smooth(o.suff[2j + 1], gx, w)
        rda_update!(o, j)
    end
end
function _updatebatchβ!(o::StatLearn{RDA}, γ, g, x, y, ŷ)
    if o.nup == 1
        o.suff = fill(o.suff0, length(x) * 2 + 1)
    end
    w = 1 / o.nup
    n = length(g)
    if o.intercept
        ḡ = mean(g)
        o.suff0 += ḡ * ḡ
        o.suff[1] = smooth(o.suff[1], ḡ, w)
        o.β0 = - o.nup * o.η * o.suff[1] / sqrt(o.suff0)
    end
    for j in 1:length(o.β)
        gx = 0.0
        for i in 1:n
            gx = g[i] * x[i, j]
        end
        gx /= n
        o.suff[2j] += gx * gx
        o.suff[2j + 1] = smooth(o.suff[2j + 1], gx, w)
        rda_update!(o, j)
    end
end

# NoPenalty
function rda_update!{M<:ModelDef}(o::StatLearn{RDA, M, NoPenalty}, j::Int)
    o.β[j] = -rda_γ(o, j) * o.suff[2j + 1]
end
# L2Penalty
function rda_update!{M<:ModelDef}(o::StatLearn{RDA, M, L2Penalty}, j::Int)
    o.suff[2j + 1] += (1 / o.nup) * o.λ * o.β[j]  # add in penalty gradient
    o.β[j] = -rda_γ(o,j) * o.suff[2j+1]
end
# L1Penalty (http://www.magicbroom.info/Papers/DuchiHaSi10.pdf)
function rda_update!{M<:ModelDef}(o::StatLearn{RDA, M, L1Penalty}, j::Int)
    ḡ = o.suff[2j + 1]
    o.β[j] = sign(-ḡ) * rda_γ(o, j) * max(0.0, abs(ḡ) - o.λ)
end
# ElasticNetPenalty
function rda_update!{M<:ModelDef}(o::StatLearn{RDA, M, ElasticNetPenalty}, j::Int)
    o.suff[2j + 1] += (1 / o.nup) * o.λ * (1 - o.penalty.α) * o.β[j]
    ḡ = o.suff[2j + 1]
    o.β[j] = sign(-ḡ) * rda_γ(o, j) * max(0.0, abs(ḡ) - o.λ * o.penalty.α)
end
# adaptive weight for element j
rda_γ(o::StatLearn{RDA}, j::Int) = o.nup * o.η / sqrt(o.suff[2j])


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


function _updateβ!(o::StatLearn{MMGrad}, γ, g, x, y, ŷ)
    if o.intercept
        o.suff0 = smooth(o.suff0, mmsuff(o, 1.0, x, y, ŷ), γ)
        setβ0!(o, γ, g / o.suff0)
    end
    for j in 1:length(o.β)
        o.suff[j] = smooth(o.suff[j], mmsuff(o, x[j], x, y, ŷ), γ)
        @inbounds o.β[j] = prox(o.penalty, o.λ, o.β[j] - γ * g * x[j] / o.suff[j], γ)
    end
end
function _updatebatchβ!(o::StatLearn{MMGrad}, γ, g, x, y, ŷ)
    n = length(g)
    if o.intercept
        v = 0.0
        for i in 1:n
            v += mmsuff(o, 1.0, row(x, i), y[i], ŷ[i])
        end
        o.suff0 = smooth(o.suff0, v / n, γ)
        setβ0!(o, γ, mean(g) / o.suff0)
    end
    for j in 1:length(o.β)
        v = 0.0
        u = 0.0
        for i in 1:n
            xij = x[i, j]
            v += mmsuff(o, xij, row(x, i), y[i], ŷ[i])
            u += g[i] * xij
        end
        o.suff[j] = smooth(o.suff[j], v / n, γ)
        @inbounds o.β[j] = prox(o.penalty, o.λ, o.β[j] - γ * u / n / o.suff[j], γ)
    end
end


#--------------------------------------------------------------------# AdaMMGrad
function _updateβ!(o::StatLearn{AdaMMGrad}, γ, g, x, y, ŷ)
    if o.intercept
        o.suff0 += mmsuff(o, 1.0, x, y, ŷ)
        setβ0!(o, o.η / sqrt(o.suff0), g)
    end
    for j in 1:length(o.β)
        o.suff[j] += mmsuff(o, x[j], x, y, ŷ)
        γ = o.η / sqrt(o.suff[j])
        o.β[j] = prox(o.penalty, o.λ, o.β[j] - o.η * γ * g * x[j], γ)
    end
end
function _updatebatchβ!(o::StatLearn{AdaMMGrad}, γ, g, x, y, ŷ)
    n = length(g)
    if o.intercept
        v = 0.0
        for i in 1:n
            v += mmsuff(o, 1.0, row(x,i), y[i], ŷ[i])
        end
        o.suff0 += v / n
        setβ0!(o, o.η / sqrt(o.suff0), mean(g))
    end
    for j in 1:length(o.β)
        v = 0.0
        u = 0.0
        for i in 1:n
            xij = x[i, j]
            v += mmsuff(o, xij, row(x, i), y[i], ŷ[i])
            u += g[i] * xij
        end
        o.suff[j] += v / n
        γ = o.η / sqrt(o.suff[j])
        o.β[j] = prox(o.penalty, o.λ, o.β[j] - o.η * γ * u / n, γ)
    end
end


#----------------------------------------------------------------------# MMGrad2
# function mmsuff2{A<:Algorithm}(o::StatLearn{A, L2Regression}, xj, x, y, ŷ)
#     xj^2 / _α(o, xj, x)
# end
# function mmsuff2{A<:Algorithm}(o::StatLearn{A, LogisticRegression}, xj, x, y, ŷ)
#     xj^2 / _α(o, xj, x) * (ŷ * (1 - ŷ))
# end
# function mmsuff2{A<:Algorithm}(o::StatLearn{A, PoissonRegression}, xj, x, y, ŷ)
#     xj^2 * ŷ / _α(o, xj, x)
# end
# function mmsuff2{A<:Algorithm}(o::StatLearn{A, QuantileRegression}, xj, x, y, ŷ)
#     xj^2 / (_α(o, xj, x) * abs(y - ŷ))
# end
# function _updateβ!(o::StatLearn{MMGrad2}, γ, g, x, y, ŷ)
#     if o.intercept
#         o.suff0 = smooth(o.suff0, mmsuff2(o, 1.0, x, y, ŷ), γ)
#         setβ0!(o, γ, g / o.suff0)
#     end
#     for j in 1:length(o.β)
#         o.suff[j] = smooth(o.suff[j], mmsuff2(o, x[j], x, y, ŷ), γ)
#         @inbounds o.β[j] = prox(o.penalty, o.λ, o.β[j] - γ * g * x[j] / o.suff[j], γ)
#     end
# end
# function _updatebatchβ!(o::StatLearn{MMGrad2}, γ, g, x, y, ŷ)
#     n = length(g)
#     if o.intercept
#         v = 0.0
#         for i in 1:n
#             v += mmsuff2(o, 1.0, row(x, i), y[i], ŷ[i])
#         end
#         o.suff0 = smooth(o.suff0, v / n, γ)
#         setβ0!(o, γ, mean(g) / o.suff0)
#     end
#     for j in 1:length(o.β)
#         v = 0.0
#         u = 0.0
#         for i in 1:n
#             xij = x[i, j]
#             v += mmsuff2(o, xij, row(x, i), y[i], ŷ[i])
#             u += g[i] * xij
#         end
#         o.suff[j] = smooth(o.suff[j], v / n, γ)
#         @inbounds o.β[j] = prox(o.penalty, o.λ, o.β[j] - γ * u / n / o.suff[j], γ)
#     end
# end
