#----------------------------------------------------------------------------# Coefficients
"""
    Coefficients(p::Integer, λ::VecF)
Structure for storing the solution path of a `StatLearn` model.
"""
struct Coefficients
    β::MatF
    λ::VecF
    function Coefficients(β::MatF, λ)
        size(β, 2) == length(λ) || throw(DimensionMismatch())
        new(β, λ)
    end
end
Coefficients(p::Int, λ::VecF) = Coefficients(randn(p, length(λ)) / 1000, λ)
function Base.show(io::IO, o::Coefficients)
    header(io, name(o))
    println(io)
    for (i, λ) in enumerate(o.λ)
        print(io, @sprintf("%4s", "$i:"))
        print(io, @sprintf("%12s", "β($(round(λ,3))) = "))
        show(io, o.β[:, i]')
        println(io)
    end
end

#-----------------------------------------------------------------------------# StatLearn
abstract type Updater end
struct StatLearn{A <: Updater, L <: Loss, P <: Penalty} <: OnlineStat{(1,0), 1}
    θ::Coefficients
    loss::L
    penalty::P
    factor::VecF
    algorithm::A
    # buffers
    xβ::VecF
    g::VecF
end
function StatLearn(p::Integer, l::Loss, pen::Penalty, λ::VecF, f::VecF, a::Type)
    d = length(λ)
    StatLearn(Coefficients(p, λ), l, pen, f, a(p, d), zeros(d), zeros(d))
end
nparams(o::StatLearn) = size(o.θ.β, 1)
coef(o::StatLearn) = o.θ
function Base.show(io::IO, o::StatLearn)
    header(io, name(o))
    println(io)
    show(io, o.θ)
end
default(::Type{Weight}, ::StatLearn) = LearningRate()

function fit!(o::StatLearn, x::AVec, y::Number, γ::Float64)
    At_mul_B!(o.xβ, o.θ.β, x)       # update xβ
    for k in eachindex(o.g)         # update derivatives
        o.g[k] = deriv(o.loss, y, o.xβ[k])
    end
    for (k, λ) in enumerate(o.θ.λ)  # update coefficients
        for j in 1:nparams(o)
            gx = o.g[k] * x[j]
            update_βj!(o, j, k, γ, γ, gx, λ * o.factor[j])
        end
    end
end

#----------------------------------------------------------------------------# Updaters
struct SGD <: Updater end
SGD(p, d) = SGD()
function update_βj!(o::StatLearn{SGD}, j, k, γ, ηγ, gx, λj)
    o.θ.β[j, k] -= ηγ * (gx + λj * deriv(o.penalty, o.θ.β[j, k]))
end

struct SPGD <: Updater end
SPGD(p, d) = SPGD()
function update_βj!(o::StatLearn{SPGD}, j, k, γ, ηγ, gx, λj)
    @inbounds o.θ.β[j, k] = prox(o.penalty, o.θ.β[j,k] - ηγ * gx, ηγ * λj)
end

struct ADAGRAD <: Updater
    H::MatF
end
ADAGRAD(p, d) = ADAGRAD(fill(ϵ, p, d))
function update_βj!(o::StatLearn{ADAGRAD}, j, k, γ, ηγ, gx, λj)
    U = o.algorithm
    @inbounds U.H[j, k] = OnlineStats.smooth(U.H[j, k], gx * gx, γ)
    @inbounds s = ηγ * inv(sqrt(U.H[j, k]) + ϵ)
    @inbounds o.θ.β[j, k] = prox(o.penalty, o.θ.β[j, k] - s * gx, s * λj)
end
