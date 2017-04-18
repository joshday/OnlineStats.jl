#-----------------------------------------------------------------------------# StatLearn
abstract type Updater end
abstract type SGUpdater <: Updater end
Base.show(io::IO, u::Updater) = print(io, name(u))
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
x = randn(100_000, 10)
y = x * linspace(-1, 1, 10) + randn(100_000)
o = StatLearn(10, L2DistLoss(), L1Penalty(), .1, SPGD())
s = Series(o)
fit!(s, x, y)
coef(o)
predict(o, x)
```
"""
struct StatLearn{U <: Updater, L <: Loss, P <: Penalty} <: StochasticStat{(1, 0), 1}
    β::VecF
    gx::VecF
    λfactor::VecF
    loss::L
    penalty::P
    updater::U
end
function StatLearn(p::Integer, l::Loss, pen::Penalty, λ::Float64, u::Updater = SPGD())
    StatLearn(zeros(p), zeros(p), ones(p) * λ, l, pen, init(u, p))
end
function Base.show(io::IO, o::StatLearn)
    header(io, name(o))
    println(io)
    print_item(io, "β", o.β')
    print_item(io, "λ factor", o.λfactor')
    print_item(io, "Loss", o.loss)
    print_item(io, "Penalty", o.penalty)
    print_item(io, "Updater", o.updater, false)
end
coef(o::StatLearn) = o.β
predict(o::StatLearn, x::AVec) = dot(x, o.β)
predict(o::StatLearn, x::AMat) = x * o.β
classify(o::StatLearn, x) = sign.(predict(o, x))
loss(o::StatLearn, x, y) = mean(value(o.loss, y, predict(o, x)))
function objective(o::StatLearn, x, y)
    mean(value(o.loss, y, predict(o, x))) + value(o.penalty, o.β, o.λfactor)
end

"""
```julia
statlearnpath(p, loss, pen, λvector, updater)
```
Create a vector of `StatLearn` objects, each using one of the regularization parameters in `λvector`.
### Example
```julia
s = Series(statlearnpath(5, L1DistLoss(), L1Penalty(), collect(0:.1:1), SPGD())...)
fit!(s, randn(10000, 5), randn(10000))
```
"""
function statlearnpath(p::Integer, l::Loss, pen::Penalty, λ::VecF, u::Updater = SPGD())
    [StatLearn(p, l, pen, λj, u) for λj in λ]
end

function fit!(o::StatLearn{<:SGUpdater}, x::AVec, y::Real, γ::Float64)
    xβ = dot(x, o.β)
    g = deriv(o.loss, y, xβ)
    o.gx .= g .* x
    update!(o, γ)
end

function fitbatch!(o::StatLearn{<:SGUpdater}, x::AMat, y::AVec, γ::Float64)
    xβ = x * o.β
    g = deriv(o.loss, y, xβ)
    @inbounds for j in eachindex(o.gx)
        o.gx[j] = 0.0
        for i in eachindex(y)
            o.gx[j] += g[i] * x[i, j]
        end
    end
    scale!(o.gx, 1 / length(y))
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
