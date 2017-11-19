#-----------------------------------------------------------------------------# StatLearn
doc"""
    StatLearn(p::Int, args...)

Fit a statistical learning model of `p` independent variables for a given `loss`, `penalty`, and `λ`.  Additional arguments can be given in any order (and is still type stable):

- `loss = .5 * L2DistLoss()`: any Loss from LossFunctions.jl
- `penalty = L2Penalty()`: any Penalty (which has a `prox` method) from PenaltyFunctions.jl.
- `λ = fill(.1, p)`: a Vector of element-wise regularization parameters
- `updater = SGD()`: [`SGD`](@ref), [`ADAGRAD`](@ref), [`ADAM`](@ref), [`ADAMAX`](@ref), [`MSPIQ`](@ref)

# Details

The (offline) objective function which StatLearn approximately minimizes is

``\frac{1}{n}\sum_{i=1}^n f_i(\beta) + \sum_{j=1}^p \lambda_j g(\beta_j),``

where the ``f_i``'s are loss functions evaluated on a single observation, ``g`` is a penalty function, and the ``\lambda_j``s are nonnegative regularization parameters.

# Example
    using LossFunctions, PenaltyFunctions
    x = randn(100_000, 10)
    y = x * linspace(-1, 1, 10) + randn(100_000)
    o = StatLearn(10, .5 * L2DistLoss(), L1Penalty(), fill(.1, 10), SGD())
    s = Series(o)
    fit!(s, x, y)
    coef(o)
    predict(o, x)
"""
struct StatLearn{U <: Updater, L <: Loss, P <: Penalty} <: StochasticStat{(1, 0)}
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
    StatLearn(zeros(p), zeros(p), λf, loss, penalty, statlearn_init(updater, p))
end

statlearn_init(u::Updater, p) = u

d(p::Integer) = (fill(.1, p), L2DistLoss(), L2Penalty(), SGD())

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
    println(io, name(o))
    print(io,   "    > β       : "); showcompact(io, o.β);        println(io)
    print(io,   "    > λfactor : "); showcompact(io, o.λfactor);  println(io)
    println(io, "    > Loss    : $(o.loss)")
    println(io, "    > Penalty : $(o.penalty)")
    print(io,   "    > Updater : $(o.updater)")
end

coef(o::StatLearn) = o.β

predict(o::StatLearn, x::AbstractVector) = dot(x, o.β)

predict(o::StatLearn, x::AbstractMatrix, ::Rows = Rows()) = x * o.β

predict(o::StatLearn, x::AbstractMatrix, ::Cols) = x'o.β

classify(o::StatLearn, x, dim = Rows()) = sign.(predict(o, x, dim))

loss(o::StatLearn, x, y, dim = Rows()) = value(o.loss, y, predict(o, x, dim), AvgMode.Mean())

function value(o::StatLearn, x, y, dim = Rows())
    value(o.loss, y, predict(o, x, dim), AvgMode.Mean()) + value(o.penalty, o.β, o.λfactor)
end

function statlearnpath(o::StatLearn, αs::AbstractVector{<:Real})
    path = [copy(o) for i in 1:length(αs)]
    for i in eachindex(αs)
        path[i].λfactor .*= αs[i]
    end
    path
end

function gradient!(o::StatLearn, x::VectorOb, y::Real)
    xβ = dot(x, o.β)
    g = deriv(o.loss, y, xβ)
    gx = o.gx
    for i in eachindex(gx)
        @inbounds gx[i] = g * x[i]
    end
end
# Batch version (unused unless we add minibatch updates)
# function gradient!(o::StatLearn, x::AbstractMatrix, y::VectorOb)
#     xβ = x * o.β
#     g = deriv(o.loss, y, xβ)
#     @inbounds for j in eachindex(o.gx)
#         o.gx[j] = 0.0
#         for i in eachindex(y)
#             o.gx[j] += g[i] * x[i, j]
#         end
#     end
#     scale!(o.gx, 1 / length(y))
# end


function fit!(o::StatLearn{<:SGUpdater}, x::VectorOb, y::Real, γ::Float64)
    gradient!(o, x, y)
    update!(o, γ)
end

function Base.merge!(o::T, o2::T, γ::Float64) where {T <: StatLearn}
    o.λfactor == o2.λfactor || error("Merge failed. StatLearn objects have different λs.")
    merge!(o.updater, o2.updater, γ)
    smooth!(o.β, o2.β, γ)
end

#-----------------------------------------------------------------------# SGD
function update!(o::StatLearn{SGD}, γ)
    for j in eachindex(o.β)
        @inbounds o.β[j] = prox(o.penalty, o.β[j] - γ * o.gx[j], γ * o.λfactor[j])
    end
end
#-----------------------------------------------------------------------# NSGD
"""
    NSGD(α)

Nesterov accelerated Proximal Stochastic Gradient Descent.
"""
struct NSGD <: SGUpdater
    α::Float64
    v::VecF
    θ::VecF
    NSGD(α = 0.0, p = 0) = new(α, zeros(p), zeros(p))
end
statlearn_init(u::NSGD, p) = NSGD(u.α, p)
function fit!(o::StatLearn{NSGD}, x::VectorOb, y::Real, γ::Float64)
    U = o.updater
    for j in eachindex(o.β)
        U.θ[j] = o.β[j] - U.α * U.v[j]
    end
    ŷ = x'U.θ
    for j in eachindex(o.β)
        U.v[j] = U.α * U.v[j] + deriv(o.loss, y, ŷ) * x[j]
        @inbounds o.β[j] = prox(o.penalty, o.β[j] - γ * U.v[j], γ * o.λfactor[j])
    end
end
function Base.merge!(o::NSGD, o2::NSGD, γ::Float64)
    o.α == o2.α || error("Merge Failed.  NSGD objects use different α.")
    smooth!(o.v, o2.v, γ)
    smooth!(o.θ, o2.θ, γ)
end

#-----------------------------------------------------------------------# ADAGRAD
"""
    ADAGRAD()

Adaptive (element-wise learning rate) stochastic proximal gradient descent.
"""
mutable struct ADAGRAD <: SGUpdater
    H::VecF
    nobs::Int
    ADAGRAD(p::Integer = 0) = new(zeros(p), 0)
end
statlearn_init(u::ADAGRAD, p) = ADAGRAD(p)
function update!(o::StatLearn{ADAGRAD}, γ)
    U = o.updater
    U.nobs += 1
    @inbounds for j in eachindex(o.β)
        U.H[j] = smooth(U.H[j], o.gx[j] ^ 2, 1 / U.nobs)
        s = γ * inv(sqrt(U.H[j] + ϵ))
        o.β[j] = prox(o.penalty, o.β[j] - s * o.gx[j], s * o.λfactor[j])
    end
end
function Base.merge!(o::ADAGRAD, o2::ADAGRAD, γ::Float64)
    o.nobs += o2.nobs
    smooth!(o.H, o2.H, γ)
end

#-----------------------------------------------------------------------# ADADELTA
"""
    ADADELTA(ρ = .95)

ADADELTA ignores weight.
"""
mutable struct ADADELTA <: SGUpdater
    ρ::Float64
    g::Vector{Float64}
    Δβ::Vector{Float64}
    ADADELTA(ρ = .95, p = 0) = new(ρ, zeros(p), zeros(p))
end
statlearn_init(u::ADADELTA, p) = ADADELTA(u.ρ, p)
function update!(o::StatLearn{ADADELTA}, γ)
    U = o.updater
    ϵ = .0001
    for j in eachindex(o.β)
        U.g[j] = smooth(o.gx[j]^2, U.g[j], U.ρ)
        Δβ = sqrt(U.Δβ[j] + ϵ) / sqrt(U.g[j] + ϵ) * o.gx[j]
        o.β[j] -= Δβ
        U.Δβ[j] = smooth(Δβ^2, U.Δβ[j], U.ρ)
    end
end
function Base.merge!(o::ADADELTA, o2::ADADELTA, γ::Float64)
    o.ρ == o2.ρ || error("Merge failed.  ADADELTA objects use different ρ.")
    smooth!(o.g, o2.g, γ)
    smooth!(o.Δβ, o2.Δβ, γ)
end

#-----------------------------------------------------------------------# RMSPROP
"""
    RMSPROP(α = .9)
"""
mutable struct RMSPROP <: SGUpdater
    α::Float64
    g::Vector{Float64}
    RMSPROP(α = .9, p = 0) = new(α, zeros(p))
end
statlearn_init(u::RMSPROP, p) = RMSPROP(u.α, p)
function update!(o::StatLearn{RMSPROP}, γ)
    U = o.updater
    for j in eachindex(o.β)
        U.g[j] = U.α * U.g[j] + (1 - U.α) * o.gx[j]^2
        o.β[j] -= γ * o.gx[j] / sqrt(U.g[j] + ϵ)
    end
end
function Base.merge!(o::RMSPROP, o2::RMSPROP, γ::Float64)
    o.α == o2.α || error("RMSPROP objects use different α")
    smooth!(o.g, o2.g, γ)
end

#-----------------------------------------------------------------------# ADAM
"""
    ADAM(α1 = .99, α2 = .999)

Adaptive Moment Estimation with momentum parameters `α1` and `α2`.
"""
mutable struct ADAM <: SGUpdater
    β1::Float64
    β2::Float64
    M::VecF
    V::VecF
    nups::Int
    function ADAM(β1::Float64 = 0.99, β2::Float64 = .999, p::Integer = 0)
        @assert 0 < β1 < 1
        @assert 0 < β2 < 1
        new(β1, β2, zeros(p), zeros(p), 0)
    end
end
statlearn_init(u::ADAM, p) = ADAM(u.β1, u.β2, p)
function update!(o::StatLearn{ADAM}, γ)
    U = o.updater
    β1 = U.β1
    β2 = U.β2
    U.nups += 1
    s = γ * sqrt(1 - β2 ^ U.nups) / (1 - β1 ^ U.nups)
    @inbounds for j in eachindex(o.β)
        gx = o.gx[j] + deriv(o.penalty, o.β[j], o.λfactor[j])
        U.M[j] = smooth(gx, U.M[j], U.β1)
        U.V[j] = smooth(gx ^ 2, U.V[j], U.β2)
        o.β[j] -= s * U.M[j] / (sqrt(U.V[j]) + ϵ)
    end
end
function Base.merge!(o::ADAM, o2::ADAM, γ::Float64)
    (o.β1 == o2.β1) && (o.β2 == o2.β2) ||
        error("Merge failed.  ADAM objects use different momentum parameters.")
    o.nups += o2.nups 
    smooth!(o.M, o2.M, γ)
    smooth!(o.V, o2.V, γ)
end

#-----------------------------------------------------------------------# ADAMAX
"""
    ADAMAX(η, β1 = .9, β2 = .999)

ADAMAX with step size `η` and momentum parameters `β1`, `β2`
"""
mutable struct ADAMAX <: SGUpdater
    β1::Float64
    β2::Float64
    M::VecF
    V::VecF
    nups::Int
    function ADAMAX(β1::Float64 = 0.9, β2::Float64 = .999, p::Integer = 0)
        @assert 0 < β1 < 1
        @assert 0 < β2 < 1
        new(β1, β2, zeros(p), zeros(p), 0)
    end
end
statlearn_init(u::ADAMAX, p) = ADAMAX(u.β1, u.β2, p)
function update!(o::StatLearn{ADAMAX}, γ)
    U = o.updater
    U.nups += 1
    s = γ * sqrt(1 - U.β2 ^ U.nups) / (1 - U.β1 ^ U.nups)
    @inbounds for j in eachindex(o.β)
        gx = o.gx[j] + deriv(o.penalty, o.β[j], o.λfactor[j])
        U.M[j] = smooth(gx, U.M[j], U.β1)
        U.V[j] = max(U.β2 * U.V[j], abs(gx))
        o.β[j] -= s * (U.M[j] / (1 - U.β1 ^ U.nups)) / (U.V[j] + ϵ)
    end
end
function Base.merge!(o::ADAMAX, o2::ADAMAX, γ::Float64)
    (o.β1 == o2.β1) && (o.β2 == o2.β2) ||
        error("Merge failed.  ADAMAX objects use different momentum parameters.")
    o.nups += o2.nups 
    smooth!(o.M, o2.M, γ)
    smooth!(o.V, o2.V, γ)
end

#-----------------------------------------------------------------------# NADAM
"""
    NADAM(α1 = .99, α2 = .999)

Adaptive Moment Estimation with momentum parameters `α1` and `α2`.
"""
mutable struct NADAM <: SGUpdater
    β1::Float64
    β2::Float64
    M::VecF
    V::VecF
    nups::Int
    function NADAM(β1::Float64 = 0.99, β2::Float64 = .999, p::Integer = 0)
        @assert 0 < β1 < 1
        @assert 0 < β2 < 1
        new(β1, β2, zeros(p), zeros(p), 0)
    end
end
statlearn_init(u::NADAM, p) = NADAM(u.β1, u.β2, p)
function update!(o::StatLearn{NADAM}, γ)
    U = o.updater
    β1 = U.β1
    β2 = U.β2
    U.nups += 1
    @inbounds for j in eachindex(o.β)
        gx = o.gx[j] + deriv(o.penalty, o.β[j], o.λfactor[j])
        U.M[j] = smooth(gx, U.M[j], U.β1)
        U.V[j] = smooth(gx ^ 2, U.V[j], U.β2)
        mt = U.M[j] / (1 - U.β1 ^ U.nups)
        vt = U.V[j] / (1 - U.β2 ^ U.nups)
        Δ = γ / (sqrt(vt + ϵ)) * (U.β1 * mt + (1 - U.β1) / (1 - U.β1^U.nups) * gx)
        o.β[j] -= Δ
    end
end
function Base.merge!(o::NADAM, o2::NADAM, γ::Float64)
    (o.β1 == o2.β1) && (o.β2 == o2.β2) ||
        error("Merge failed.  NADAM objects use different momentum parameters.")
    o.nups += o2.nups 
    smooth!(o.M, o2.M, γ)
    smooth!(o.V, o2.V, γ)
end


#-----------------------------------------------------------------------#
#-----------------------------------------------------------------------#
#-----------------------------------------------------------------------# Majorization-based
# Updaters below here are experimental and may change.

# const LinearRegression      = LossFunctions.ScaledDistanceLoss{L2DistLoss,0.5}
const L1Regression          = L1DistLoss
const LogisticRegression    = LogitMarginLoss
const PoissonRegression     = PoissonLoss
const HuberRegression       = HuberLoss
const SVMLike               = L1HingeLoss
const QuantileRegression    = QuantileLoss
const DWDLike               = DWDMarginLoss

# Lipschitz constant
constH(o::StatLearn{A, L}, x, y) where {A, L} = error("$A is not defined for $L")
constH(o::StatLearn{A, L2DistLoss}, x, y) where {A} = 2x'x

const L2Scaled{N} = LossFunctions.ScaledDistanceLoss{L2DistLoss, N}
constH(o::StatLearn{A, L2Scaled{N}}, x, y) where {A, N} = 2 * N * x'x 
constH(o::StatLearn{A, LogitMarginLoss}, x, y) where {A} = .25 * x'x
constH(o::StatLearn{A, <:DWDMarginLoss}, x, y) where {A} = ((o.loss.q + 1) ^ 2 / o.loss.q) * x'x


# Full Matrix for quadratic upper bound
# TODO: assume H is symmetric and optimize
fullH!(o::StatLearn{A, L2DistLoss}, x, y) where {A} = (o.updater.H[:] = 2 * x * x')
fullH!(o::StatLearn{A, L2Scaled{N}}, x, y) where {A, N} = (o.updater.H[:] = 2 * N * x * x')
fullH!(o::StatLearn{A, LogitMarginLoss}, x, y) where {A} = (o.updater.H[:] = .25 * x * x')
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
statlearn_init(u::OMASQ, p) = OMASQ(0.0, zeros(p))
Base.merge!(o::OMASQ, o2::OMASQ, γ::Float64) = smooth!(o.b, o2.b, γ)

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


#-----------------------------------------------------------------------# OMAPQ
struct OMAPQ <: Updater end
function fit!(o::StatLearn{OMAPQ}, x::VectorOb, y::Real, γ::Float64)
    gradient!(o, x, y)
    h_inv = inv(constH(o, x, y))
    for j in eachindex(o.β)
        o.β[j] -= γ * h_inv * o.gx[j]
    end
end
Base.merge!(o::OMAPQ, o2::OMAPQ, γ::Float64) = nothing
# #-----------------------------------------------------------------------# OMAPQF
# struct OMAPQF <: Updater
#     H::Matrix{Float64}
#     OMAPQF(p = 0) = new(η, zeros(p, p))
# end
# Base.show(io::IO, u::OMAPQF) = print(io, "OMAPQF")
# statlearn_init(o::OMAPQF, p) = OMAPQF(p)
# function fit!(o::StatLearn{OMAPQF}, x::VectorOb, y::Real, γ::Float64)
#     gradient!(o, x, y)
#     fullH!(o, x, y)
#     o.β[:] -= γ * ((o.updater.H + ϵ * I) \ o.gx)
# end

#-----------------------------------------------------------------------# MSPIQ
"""
    MSPIQ()

MSPI-Q (Proximal mapping applied to majorization) algorithm using a Lipschitz constant to 
majorize the objective.  
"""
struct MSPIQ <: Updater end
function fit!(o::StatLearn{MSPIQ}, x::VectorOb, y::Real, γ::Float64)
    gradient!(o, x, y)
    denom = inv(1 + γ * constH(o, x, y))
    for j in eachindex(o.β)
        @inbounds o.β[j] -= γ * denom * o.gx[j]
    end
end
Base.merge!(o::MSPIQ, o2::MSPIQ, γ::Float64) = nothing

#-----------------------------------------------------------------------# MSPI
function fit!(o::StatLearn{<:MSPI}, x::VectorOb, y::Real, γ::Float64)
    gradient!(o, x, y)
    denom = inv(1 + γ * constH(o, x, y))
    for j in eachindex(o.β)
        @inbounds o.β[j] -= γ * denom * o.gx[j]
    end
end