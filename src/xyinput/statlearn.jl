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
Coefficients(p::Int, λ::VecF) = Coefficients(randn(p, length(λ)), λ)
function Base.show(io::IO, o::Coefficients)
    header(io, name(o))
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
function StatLearn(d::Integer, l::Loss, p::Penalty, λ::VecF, f::VecF, a::Type)
    nλ = length(λ)
    StatLearn(Coefficients(d, λ), l, p, f, a(d), zeros(nλ), zeros(nλ))
end
nparams(o::StatLearn) = size(o.θ.β, 1)
Base.show(io::IO, o::StatLearn) = show(io, o.θ)
default(::Type{Weight}, ::StatLearn) = LearningRate()

function fit!(o::StatLearn, x::AVec, y::Number, γ::Float64)
    At_mul_B!(o.xβ, o.θ.β, x)       # update xβ
    for k in eachindex(o.g)         # update derivatives
        o.g[k] = deriv(o.loss, y, o.xβ[k])
    end
    update_alg!(o, x, y)            # update algorithm
    for (k, λ) in enumerate(o.θ.λ)  # update coefficients
        for j in 1:nparams(o)
            gx = o.g[k] * x[j]
            update_βj!(o, j, k, γ, γ, gx, λ * o.factor[j])
        end
    end
end

# fallback algorithm update
update_alg!(o::StatLearn, x::AVec, y::Number) = nothing


struct SGD <: Updater end
SGD(d::Integer) = SGD()
function update_βj!(o::StatLearn{SGD}, j, k, γ, ηγ, gx, λj)
    o.θ.β[j, k] -= ηγ * (gx + λj * deriv(o.penalty, o.θ.β[j, k]))
end

struct SPGD <: Updater end
SPGD(d::Integer) = SPGD()
function update_βj!(o::StatLearn{SPGD}, j, k, γ, ηγ, gx, λj)
    @inbounds o.θ.β[j, k] = prox(o.penalty, o.θ.β[j,k] - ηγ * gx, ηγ * λj)
end
