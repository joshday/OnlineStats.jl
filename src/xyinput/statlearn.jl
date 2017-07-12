#-----------------------------------------------------------------------------# StatLearn
abstract type Updater end
abstract type SGUpdater <: Updater end
function Base.show(io::IO, u::Updater)
    print(io, OnlineStatsBase.name(u))
    OnlineStatsBase.show_fields(io, u)
end
OnlineStatsBase.fields_to_show(u::Updater) = [:η]
init(u::Updater, p) = u


"""
```julia
StatLearn(p, loss, penalty, λ, updater)
```
Fit a statistical learning model of `p` independent variables for a given `loss`, `penalty`, and `λ`.  Arguments are:
- `loss`: any Loss from LossFunctions.jl
- `penalty`: any Penalty from PenaltyFunctions.jl.
- `λ`: a Float64 regularization parameter
- `updater`: `SPGD()`, `ADAGRAD()`, `ADAM()`, or `ADAMAX()`

### Example
```julia
using LossFunctions, PenaltyFunctions
x = randn(100_000, 10)
y = x * linspace(-1, 1, 10) + randn(100_000)
o = StatLearn(10, L2DistLoss(), L1Penalty(), .1, SPGD())
s = Series(o)
fit!(s, x, y)
coef(o)
predict(o, x)
```
"""
struct StatLearn{U <: Updater, L <: Loss, P <: Penalty} <: OnlineStat{(1, 0), 1, LearningRate}
    β::VecF
    gx::VecF
    λfactor::VecF
    loss::L
    penalty::P
    updater::U
end
function StatLearn{V,L,P,U}(p::Integer, t::Tuple{V,L,P,U})
    λf, loss, penalty, updater = t
    length(λf) == p || throw(DimensionMismatch("lengths of λfactor and β differ"))
    StatLearn(zeros(p), zeros(p), λf, loss, penalty, init(updater, p))
end

d(p::Integer) = (fill(.1, p), L2DistLoss(), L2Penalty(), SPGD())

a(argu::VecF, t)     = (argu, t[2], t[3], t[4])
a(argu::Loss, t)     = (t[1], argu, t[3], t[4])
a(argu::Penalty, t)  = (t[1], t[2], argu, t[4])
a(argu::Updater, t)  = (t[1], t[2], t[3], argu)

StatLearn(p::Integer)                 = StatLearn(p, d(p))
StatLearn(p::Integer, a1)             = StatLearn(p, a(a1, d(p)))
StatLearn(p::Integer, a1, a2)         = StatLearn(p, a(a2, a(a1, d(p))))
StatLearn(p::Integer, a1, a2, a3)     = StatLearn(p, a(a3, a(a2, a(a1, d(p)))))
StatLearn(p::Integer, a1, a2, a3, a4) = StatLearn(p, a(a4, a(a3, a(a2, a(a1, d(p))))))

function Base.show(io::IO, o::StatLearn)
    println(io, OnlineStatsBase.name(o))
    println(io, "    > β       : $(o.β)")
    println(io, "    > λfactor : $(o.λfactor)")
    println(io, "    > Loss    : $(o.loss)")
    println(io, "    > Penalty : $(o.penalty)")
    print(io,   "    > Updater : $(o.updater)")
end

coef(o::StatLearn) = o.β
predict(o::StatLearn, x::AVec) = dot(x, o.β)
predict(o::StatLearn, x::AMat) = x * o.β
classify(o::StatLearn, x) = sign.(predict(o, x))
loss(o::StatLearn, x, y) = value(o.loss, y, predict(o, x), AvgMode.Mean())
function objective(o::StatLearn, x, y)
    mean(value(o.loss, y, predict(o, x))) + value(o.penalty, o.β, o.λfactor)
end


function statlearnpath(o::StatLearn, αs::AbstractVector{<:Real})
    path = [copy(o) for i in 1:length(αs)]
    for i in eachindex(αs)
        path[i].λfactor .*= αs[i]
    end
    path
end



function gradient!(o::StatLearn, x::AVec, y::Real, γ::Float64)
    xβ = dot(x, o.β)
    g = deriv(o.loss, y, xβ)
    o.gx .= g .* x
end
function gradient!(o::StatLearn, x::AMat, y::AVec, γ::Float64)
    xβ = x * o.β
    g = deriv(o.loss, y, xβ)
    @inbounds for j in eachindex(o.gx)
        o.gx[j] = 0.0
        for i in eachindex(y)
            o.gx[j] += g[i] * x[i, j]
        end
    end
    scale!(o.gx, 1 / length(y))
end
function fit!(o::StatLearn{<:SGUpdater}, x::VectorObservation, y::Real, γ::Float64)
    gradient!(o, x, y, γ)
    update!(o, γ)
end
function fitbatch!(o::StatLearn{<:SGUpdater}, x::AMat, y::AVec, γ::Float64)
    gradient!(o, x, y, γ)
    update!(o, γ)
end




#-----------------------------------------------------------------------# SPGD
"""
    SPGD(η)
Stochastic Proximal Gradient Descent with step size `η`
"""
struct SPGD <: SGUpdater
    η::Float64
    SPGD(η::Float64 = 1.0) = new(η)
end
function update!(o::StatLearn{SPGD}, γ)
    γη = γ * o.updater.η
    for j in eachindex(o.β)
        @inbounds o.β[j] = prox(o.penalty, o.β[j] - γη * o.gx[j], γη * o.λfactor[j])
    end
end
#-----------------------------------------------------------------------# MAXSPGD
"""
    MAXSPGD(η)
SPGD where only the largest gradient element is used to update the parameter.
"""
struct MAXSPGD <: SGUpdater
    η::Float64
    MAXSPGD(η::Float64 = 1.0) = new(η)
end
function update!(o::StatLearn{MAXSPGD}, γ)
    γη = γ * o.updater.η
    j = indmax(abs(gx) for gx in o.gx)
    @inbounds o.β[j] = prox(o.penalty, o.β[j] - γη * o.gx[j], γη * o.λfactor[j])
end

#-----------------------------------------------------------------------# ADAGRAD
"""
    ADAGRAD(η)
Adaptive (element-wise learning rate) SPGD with step size `η`
"""
struct ADAGRAD <: SGUpdater
    η::Float64
    H::VecF
    ADAGRAD(η::Float64 = 1.0, p::Integer = 0) = new(η, zeros(p))
end
init(u::ADAGRAD, p) = ADAGRAD(u.η, p)
function update!(o::StatLearn{ADAGRAD}, γ)
    U = o.updater
    @inbounds for j in eachindex(o.β)
        U.H[j] = smooth(U.H[j], o.gx[j] ^ 2, γ)
        s = U.η * γ * inv(sqrt(U.H[j]) + ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - s * o.gx[j], s * o.λfactor[j])
    end
end

#-----------------------------------------------------------------------# ADAM
"""
    ADAM(α1, α2, η)
Adaptive Moment Estimation with step size `η` and momentum parameters `α1`, `α2`
"""
mutable struct ADAM <: SGUpdater
    α1::Float64
    α2::Float64
    η::Float64
    M::VecF
    V::VecF
    nups::Int
    function ADAM(α1::Float64 = 0.1, α2::Float64 = .001, η::Float64 = 1.0, p::Integer = 0)
        @assert 0 < α1 < 1
        @assert 0 < α2 < 1
        new(α1, α2, η, zeros(p), zeros(p), 0)
    end
end
init(u::ADAM, p) = ADAM(u.α1, u.α2, u.η, p)
function update!(o::StatLearn{ADAM}, γ)
    U = o.updater
    β1 = 1 - U.α1
    β2 = 1 - U.α2
    U.nups += 1
    s = γ * sqrt(1 - β2 ^ U.nups) / (1 - β1 ^ U.nups)
    @inbounds for j in eachindex(o.β)
        gx = o.gx[j] + deriv(o.penalty, o.β[j], o.λfactor[j])
        U.M[j] = smooth(U.M[j], gx, U.α1)
        U.V[j] = smooth(U.V[j], gx ^ 2, U.α2)
        o.β[j] -= s * U.M[j] / (sqrt(U.V[j]) + ϵ)
    end
end

#-----------------------------------------------------------------------# ADAMAX
"""
    ADAMAX(α1, α2, η)
ADAMAX with step size `η` and momentum parameters `α1`, `α2`
"""
mutable struct ADAMAX <: SGUpdater
    α1::Float64
    α2::Float64
    η::Float64
    M::VecF
    V::VecF
    nups::Int
    function ADAMAX(α1::Float64 = 0.1, α2::Float64 = .001, η::Float64 = 1.0, p::Integer = 0)
        @assert 0 < α1 < 1
        @assert 0 < α2 < 1
        new(α1, α2, η, zeros(p), zeros(p), 0)
    end
end
init(u::ADAMAX, p) = ADAMAX(u.α1, u.α2, u.η, p)
function update!(o::StatLearn{ADAMAX}, γ)
    U = o.updater
    β1 = 1 - U.α1
    β2 = 1 - U.α2
    U.nups += 1
    s = γ * sqrt(1 - β2 ^ U.nups) / (1 - β1 ^ U.nups)
    @inbounds for j in eachindex(o.β)
        gx = o.gx[j] + deriv(o.penalty, o.β[j], o.λfactor[j])
        U.M[j] = smooth(U.M[j], gx, U.α1)
        U.V[j] = max(β2 * U.V[j], abs(gx))
        o.β[j] -= s * U.M[j] / (U.V[j] + ϵ)
    end
end

#-----------------------------------------------------------------------# MMXTX
"""
    MMXTX(c)
Online MM algorithm via quadratic approximation.  Approximates Lipschitz
constant with `x'x * c * I`.
"""
mutable struct MMXTX <: Updater
    c::Float64
    h::Float64
    b::VecF
end
MMXTX(c::Float64 = 1.0) = MMXTX(c, 0.0, zeros(0))
init(u::MMXTX, p) = MMXTX(u.c, 0.0, zeros(p))
Base.show(io::IO, u::MMXTX) = print(io, "MMXTX(c = $(u.c))")

function fit!(o::StatLearn{MMXTX}, x::VectorObservation, y::Real, γ::Float64)
    U = o.updater
    gradient!(o, x, y, γ)
    U.h = smooth(U.h, x'x * U.c, γ)
    for j in eachindex(o.β)
        U.b[j] = smooth(U.b[j], U.h * o.β[j] - o.gx[j], γ)
        o.β[j] = U.b[j] / U.h
    end
end
function fitbatch!(o::StatLearn{MMXTX}, x::AMat, y::AVec, γ::Float64)
    U = o.updater
    gradient!(o, x, y, γ)
    U.h = smooth(U.h, mean(sum(abs2, x, 2)) * U.c, γ)
    for j in eachindex(o.β)
        U.b[j] = smooth(U.b[j], U.h * o.β[j] - o.gx[j], γ)
        o.β[j] = U.b[j] / U.h
    end
end


#-----------------------------------------------------------------------# MSPI
"""
    MSPI()
Majorized Stochastic Proximal Iteration.
Uses quadratic upper bound with `x'x * c * I`.
"""
struct MSPI <: Updater
    c::Float64
    MSPI(c = 1.0) = new(c)
end
Base.show(io::IO, u::MSPI) = print(io, "MSPI(c = $(u.c))")
function fit!(o::StatLearn{MSPI}, x::VectorObservation, y::Real, γ::Float64)
    gradient!(o, x, y, γ)
    denom = inv(1 + γ * x'x * o.updater.c)
    xtx = x'x * o.updater.c
    for j in eachindex(o.β)
        o.β[j] -= γ * denom * o.gx[j]
    end
end
