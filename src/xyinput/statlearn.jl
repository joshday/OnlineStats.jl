const LinearRegression      = LossFunctions.ScaledDistanceLoss{L2DistLoss,0.5}
const L1Regression          = L1DistLoss
const LogisticRegression    = LogitMarginLoss
const PoissonRegression     = PoissonLoss
const HuberRegression       = HuberLoss
const SVMLike               = L1HingeLoss
const QuantileRegression    = QuantileLoss
const DWDLike               = DWDMarginLoss

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
- `λ`: a Vector of element-wise regularization parameters
- `updater`: `SPGD()`, `ADAGRAD()`, `ADAM()`, or `ADAMAX()`

### Example
```julia
using LossFunctions, PenaltyFunctions
x = randn(100_000, 10)
y = x * linspace(-1, 1, 10) + randn(100_000)
o = StatLearn(10, L2DistLoss(), L1Penalty(), fill(.1, 10), SPGD())
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
    print(io, "    > β       : "); showcompact(io, o.β);        println(io)
    print(io, "    > λfactor : "); showcompact(io, o.λfactor);  println(io)
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



function gradient!(o::StatLearn, x::AVec, y::Real)
    xβ = dot(x, o.β)
    g = deriv(o.loss, y, xβ)
    o.gx .= g .* x
end
function gradient!(o::StatLearn, x::AMat, y::AVec)
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
function fit!(o::StatLearn{<:SGUpdater}, x::VectorOb, y::Real, γ::Float64)
    gradient!(o, x, y)
    update!(o, γ)
end




#-----------------------------------------------------------------------# SPGD
"""
    SPGD(η)
Stochastic Proximal Gradient Descent with step size `η`
"""
struct SPGD <: SGUpdater
    η::Float64
    SPGD(η::Real = 1.0) = new(η)
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
    ADAM(η, α1, α2)
Adaptive Moment Estimation with step size `η` and momentum parameters `α1`, `α2`
"""
mutable struct ADAM <: SGUpdater
    α1::Float64
    α2::Float64
    η::Float64
    M::VecF
    V::VecF
    nups::Int
    function ADAM(η::Float64 = 1.0, α1::Float64 = 0.1, α2::Float64 = .001, p::Integer = 0)
        @assert 0 < α1 < 1
        @assert 0 < α2 < 1
        new(α1, α2, η, zeros(p), zeros(p), 0)
    end
end
init(u::ADAM, p) = ADAM(u.η, u.α1, u.α2, p)
function update!(o::StatLearn{ADAM}, γ)
    U = o.updater
    β1 = 1 - U.α1
    β2 = 1 - U.α2
    U.nups += 1
    s = γ * U.η * sqrt(1 - β2 ^ U.nups) / (1 - β1 ^ U.nups)
    @inbounds for j in eachindex(o.β)
        gx = o.gx[j] + deriv(o.penalty, o.β[j], o.λfactor[j])
        U.M[j] = smooth(U.M[j], gx, U.α1)
        U.V[j] = smooth(U.V[j], gx ^ 2, U.α2)
        o.β[j] -= s * U.M[j] / (sqrt(U.V[j]) + ϵ)
    end
end

#-----------------------------------------------------------------------# ADAMAX
"""
    ADAMAX(η, α1, α2)
ADAMAX with step size `η` and momentum parameters `α1`, `α2`
"""
mutable struct ADAMAX <: SGUpdater
    α1::Float64
    α2::Float64
    η::Float64
    M::VecF
    V::VecF
    nups::Int
    function ADAMAX(η::Float64 = 1.0, α1::Float64 = 0.1, α2::Float64 = .001, p::Integer = 0)
        @assert 0 < α1 < 1
        @assert 0 < α2 < 1
        new(α1, α2, η, zeros(p), zeros(p), 0)
    end
end
init(u::ADAMAX, p) = ADAMAX(u.η, u.α1, u.α2, p)
function update!(o::StatLearn{ADAMAX}, γ)
    U = o.updater
    β1 = 1 - U.α1
    β2 = 1 - U.α2
    U.nups += 1
    s = U.η * γ * sqrt(1 - β2 ^ U.nups) / (1 - β1 ^ U.nups)
    @inbounds for j in eachindex(o.β)
        gx = o.gx[j] + deriv(o.penalty, o.β[j], o.λfactor[j])
        U.M[j] = smooth(U.M[j], gx, U.α1)
        U.V[j] = max(β2 * U.V[j], abs(gx))
        o.β[j] -= s * U.M[j] / (U.V[j] + ϵ)
    end
end



#-----------------------------------------------------------------------#
#-----------------------------------------------------------------------#
#-----------------------------------------------------------------------# Majorization-based
# Updaters below here are experimental and may change.

const LinearRegression      = LossFunctions.ScaledDistanceLoss{L2DistLoss,0.5}
const L1Regression          = L1DistLoss
const LogisticRegression    = LogitMarginLoss
const PoissonRegression     = PoissonLoss
const HuberRegression       = HuberLoss
const SVMLike               = L1HingeLoss
const QuantileRegression    = QuantileLoss
const DWDLike               = DWDMarginLoss

# Lipschitz constant
constH{A, L}(o::StatLearn{A, L}, x, y) = error("$A is not defined for $L")
constH{A}(o::StatLearn{A, L2DistLoss}, x, y)       = 2x'x
constH{A}(o::StatLearn{A, LinearRegression}, x, y) = x'x
constH{A}(o::StatLearn{A, LogitMarginLoss}, x, y)  = .25 * x'x
constH{A}(o::StatLearn{A, <:DWDMarginLoss}, x, y)  = ((o.loss.q + 1) ^ 2 / o.loss.q) * x'x

# Diagonal Matrix for quadratic upper bound
diagH!{A, L}(o::StatLearn{A, L}, x, y) = error("$A is not defined for $L")

# Full Matrix for quadratic upper bound
# TODO: assume H is symmetric and optimizie
fullH!{A, L}(o::StatLearn{A, L}, x, y) = error("$A is not defined for $L")
fullH!{A}(o::StatLearn{A, L2DistLoss}, x, y)       = (o.updater.H[:] = 2 * x * x')
fullH!{A}(o::StatLearn{A, LinearRegression}, x, y) = (o.updater.H[:] = x * x')
fullH!{A}(o::StatLearn{A, LogitMarginLoss}, x, y)  = (o.updater.H[:] = .25 * x * x')
function fullH!{A}(o::StatLearn{A, <:DWDMarginLoss}, x, y)
    o.updater.H[:] = ((o.loss.q + 1) ^ 2 / o.loss.q) * x * x'
end

#-----------------------------------------------------------------------# OMASQ
"Experimental: OMM-constant"
mutable struct OMASQ <: Updater
    h::Float64
    b::VecF
end
OMASQ() = OMASQ(0.0, zeros(0))
init(u::OMASQ, p) = OMASQ(0.0, zeros(p))
Base.show(io::IO, u::OMASQ) = print(io, "OMASQ")

function fit!(o::StatLearn{OMASQ}, x::VectorOb, y::Real, γ::Float64)
    U = o.updater
    gradient!(o, x, y)
    ht = constH(o, x, y)
    U.h = smooth(U.h, ht, γ)
    for j in eachindex(o.β)
        U.b[j] = smooth(U.b[j], ht * o.β[j] - o.gx[j], γ)
        o.β[j] = U.b[j] / U.h
    end
end

#-----------------------------------------------------------------------# OMASQF
"Experimental: OMM-full matrix"
mutable struct OMASQF <: Updater
    H::Matrix{Float64}
    smoothedH::Matrix{Float64}
    b::VecF
end
OMASQF() = OMASQF(zeros(0, 0), zeros(0, 0), zeros(0))
init(u::OMASQF, p) = OMASQF(zeros(p, p), zeros(p, p), zeros(p))
Base.show(io::IO, u::OMASQF) = print(io, "OMASQF")

function fit!(o::StatLearn{OMASQF}, x::VectorOb, y::Real, γ::Float64)
    U = o.updater
    gradient!(o, x, y)
    fullH!(o, x, y)
    smooth!(U.smoothedH, U.H, γ)
    smooth!(U.b, U.H * o.β - o.gx, γ)
    try
        o.β[:] = (U.smoothedH + ϵ * I) \ U.b
    end
end

#-----------------------------------------------------------------------# OMAPQ
struct OMAPQ <: Updater end
Base.show(io::IO, u::OMAPQ) = print(io, "OMAPQ")
function fit!(o::StatLearn{OMAPQ}, x::VectorOb, y::Real, γ::Float64)
    gradient!(o, x, y)
    h_inv = inv(constH(o, x, y))
    for j in eachindex(o.β)
        o.β[j] -= γ * h_inv * o.gx[j]
    end
end
#-----------------------------------------------------------------------# OMAPQF
struct OMAPQF <: Updater
    H::Matrix{Float64}
    OMAPQF(p = 0) = new(η, zeros(p, p))
end
Base.show(io::IO, u::OMAPQF) = print(io, "OMAPQF")
init(o::OMAPQF, p) = OMAPQF(p)
function fit!(o::StatLearn{OMAPQF}, x::VectorOb, y::Real, γ::Float64)
    gradient!(o, x, y)
    fullH!(o, x, y)
    o.β[:] -= γ * ((o.updater.H + ϵ * I) \ o.gx)
end

#-----------------------------------------------------------------------# MSPIC
"Experimental: MSPI-constant"
struct MSPIC <: Updater
    η::Float64
    MSPIC(η::Real = 1.) = new(η)
end
function fit!(o::StatLearn{MSPIC}, x::VectorOb, y::Real, γ::Float64)
    gradient!(o, x, y)
    ηγ = o.updater.η * γ
    denom = inv(1 + ηγ * constH(o, x, y))
    for j in eachindex(o.β)
        @inbounds o.β[j] -= ηγ * denom * o.gx[j]
    end
end

#-----------------------------------------------------------------------# MSPIF
"Experimental: MSPI-full matrix"
struct MSPIF <: Updater
    η::Float64
    H::Matrix{Float64}
    MSPIF(η::Real = 1., p = 0) = new(η, zeros(p, p))
end
init(u::MSPIF, p) = MSPIF(u.η, p)
function fit!(o::StatLearn{MSPIF}, x::VectorOb, y::Real, γ::Float64)
    gradient!(o, x, y)
    ηγ = o.updater.η * γ
    fullH!(o, x, y)
    o.β[:] = o.β - ηγ * ((I + ηγ * o.updater.H) \ o.gx)
end




#-----------------------------------------------------------------------# SPI
"Stochastic Proximal Iteration"
struct SPI <: Updater
    η::Float64
    SPI(η::Real=1.0) = new(η)
end
fit!(o::StatLearn{SPI}, x, y, γ) = spi!(o, x, y, γ * o.updater.η)

spi!(o::StatLearn, x, y, γ) = error("$(o.loss) is not defined for SPI")
function spi!(o::StatLearn{SPI, LinearRegression}, x, y, γ)
    o.β[:] = (I + γ * x * x') \ (o.β + γ * y * x)
end
spi!(o::StatLearn{SPI, L2DistLoss}, x, y, γ) = (o.β[:] = (I + 2γ * x * x') \ (o.β + 2γ * y * x))
