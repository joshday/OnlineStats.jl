#-----------------------------------------------------------------------------# Losses
"""
    l2regloss(y, xβ)

Loss function between continuous response `y` and linear predictor `xβ` based on the ``L_2`` norm:

``.5 * (y - xβ) ^ 2``
"""
l2regloss(y, yhat) = .5 * abs2(y - yhat)
deriv(::typeof(l2regloss), y, yhat) = yhat - y

"""
    l1regloss(y, xβ)

Loss function between continuous response `y` and linear predictor `xβ` based on the ``L_1`` norm:

``|y - xβ|``
"""
l1regloss(y, yhat) = abs(y - yhat)
deriv(::typeof(l1regloss), y, yhat) = sign(yhat - y)

"""
    logisticloss(y, xβ)

Loss function between boolean response `y ∈ {-1, 1}` and linear predictor `xβ` for logistic regression:

``log(1 + exp(-y * xβ))``
"""
logisticloss(y, yhat) = log1p(exp(-y * yhat))
deriv(::typeof(logisticloss), y, yhat) = -y / (1 + exp(y * yhat))

"""
    l1hingeloss(y, xβ)

Loss function between boolean response `y ∈ {-1, 1}` and linear predictor `xβ` for support vector machines:

``max(1 - y * xβ, 0)``
"""
l1hingeloss(y, yhat) = max(1 - y*yhat, zero(yhat))
deriv(::typeof(l1hingeloss), y, yhat) = (u = y*yhat; u ≥ 1 ? zero(y) : -y)

"""
    DWDLoss(q)(y, xβ)

Distance-weighted discrimination loss function (smoothed `l1hingeloss`) with smoothing parameter `q`.  Loss is calculated between a boolean response `y ∈ {-1, 1}` and linear predictor `xβ`.
"""
struct DWDLoss{T<:Number}
    q::T
end
function (o::DWDLoss)(y, yhat)
    agreement = y * yhat
    q = o.q
    if agreement ≤ q / (q + 1)
        1 - agreement
    else
        (q ^ q / (q + 1) ^ (q + 1)) / agreement ^ q
    end
end
function deriv(loss::DWDLoss, y, yhat)
    u = y * yhat
    q = loss.q
    if u ≤ q / (q + 1)
        -y
    else
       - y * ( q / (q + 1)) ^ (q + 1) / u ^ (q + 1)
    end
end

#-----------------------------------------------------------------------------# Penalties
prox(::typeof(zero), x, s) = x
prox(::typeof(abs2), x, s) = x / (1 + s)
prox(::typeof(abs), x::T, s::Number) where {T} = sign(x) * max(T(0), abs(x) - s)


"""
    ElasticNet(α)

Weighted average of Ridge (`abs`) and LASSO (`abs2`) penalty functions.

``(1 - α) * Ridge + α * LASSO``
"""
struct ElasticNet{T}
    α::T
end
(p::ElasticNet)(x) = smooth(abs2(x), abs(x), p.α)
function prox(p::ElasticNet, x, s)
    αs = p.α * s
    prox(abs, x, αs) / (1 + s - αs)
end

#-----------------------------------------------------------------------------# StatLearn
"""
    StatLearn(args...; penalty=zero, rate=LearningRate())

Fit a model (via stochastic approximation) that is linear in the parameters.  The (offline)
objective function that StatLearn approximately minimizes is

``(1/n) ∑ᵢ f(yᵢ, xᵢ'β) + ∑ⱼ λⱼ g(βⱼ),``

where ``fᵢ`` are loss functions of a response variable and linear predictor, ``λⱼ``s are
nonnegative regularization parameters, and ``g`` is a penalty function.

Use `StatLearn` with caution, as stochastic approximation algorithms are inherently noisy.

# Arguments

- `loss = OnlineStats.l2regloss`: The loss function to be (approximately) minimized.
    - Regression Losses:
        - `l2regloss`: Squared error loss
        - `l1regloss`: Absolute error loss
    - Classification (y ∈ {-1, 1}) Losses:
        - `logisticloss`: Logistic regression
        - `l1hingeloss`: Loss function used in Support Vector Machines.
        - `DWDLoss(q)`: Generalized Distance Weighted Discrimination (smoothed `l1hingeloss`)
- `algorithm = MSPI()`: The stochastic approximation method to be used.
    - Algorithms based on Stochastic gradient:
        - `SGD()`: Stochastic Gradient Descent
        - `ADAGRAD()`: AdaGrad (adaptive version of SGD)
        - `RMSPROP()`: RMSProp (adaptive version of SGD)
    - Algorithms based on Majorization-Minimization Principle:
        - `MSPI()`: Majorized Stochastic Proximal Iteration
        - `OMAS()`: Online MM via Averaged Surrogate
        - `OMAP()`: Online MM via Averaged Parameter
- `λ = 0.0`: The hyperparameter(s) used for the penalty function
    - User can provide elementwise penalty hyperparameters (`Vector{Float64}`) or single hyperparameter (`Float64`).

## Keyword Arguments

- `penalty`: The regularization function used.
    - `zero`: no penalty (default)
    - `abs`: (LASSO) parameters penalized by their absolute value
    - `abs2`: (Ridge) parameters penalized by their squared value
    - `ElasticNet(α)`: α * (abs penalty) + (1-α) * (abs2 penalty)
- `rate = LearningRate(.6)`

# Example

```julia
x = randn(1000, 5)
y = x * range(-1, stop=1, length=5) + randn(1000)

o = fit!(StatLearn(MSPI()), zip(eachrow(x), y))
coef(o)

o = fit!(StatLearn(OnlineStats.l1regloss, ADAGRAD()), zip(eachrow(x), y))
coef(o)
```
"""
mutable struct StatLearn{A<:Algorithm, L, P, W} <: OnlineStat{XY}
    β::Vector{Float64}
    λ::Vector{Float64}
    gx::Vector{Float64}
    loss::L
    penalty::P
    alg::A
    rate::W
    n::Int
end
function StatLearn(args...; penalty=zero, rate=LearningRate())
    p = 0
    λ = zeros(1)
    loss = l2regloss
    alg = MSPI()
    for a in args
        if a isa AbstractVector
            λ = a
        elseif a isa Float64
            λ = fill(a, 1)
        elseif a isa Algorithm
            alg = a
        elseif a isa Integer
            p = a
        elseif hasmethod(a, (Number, Number)) && hasmethod(deriv, (typeof(a), Number, Number))
            loss = a
        else
            @warn """
            Arguments of type $(typeof(a)) are not recognized by StatLearn.  See the `StatLearn` docs for details.
            """
        end
    end
    init!(alg, p)
    StatLearn(zeros(p), λ, zeros(p), loss, penalty, alg, rate, 0)
end

function Base.show(io::IO, o::StatLearn)
    print(io, "StatLearn: ")
    print(io, name(o.alg, false, false))
    o.penalty != zero && print(io, " | mean(λ)=", mean(o.λ))
    print(io, " | ", o.loss)
    print(io, " | ", o.penalty)
    print(io, " | nobs=", nobs(o))
    print(io, " | nvars=", length(o.β))
end
coef(o::StatLearn) = value(o)

function gradient!(o::StatLearn, x, y)
    d_dη = deriv(o.loss, y, predict(o, x))
    for j in eachindex(o.gx)
        o.gx[j] = x[j] * d_dη
    end
end
function _fit!(o::StatLearn{<:SGAlgorithm}, xy)
    x, y = xy
    (o.n += 1) == 1  && init!(o, length(x))
    gradient!(o, x, y)
    update!(o.alg, o.gx)
    updateβ!(o, o.rate(o.n))
end
function init!(o::StatLearn, p)
    o.β = zeros(p)
    o.gx = zeros(p)
    init!(o.alg, p)
    if length(o.λ) == 1
        o.λ = fill(o.λ[1], p)
    end
end

function _merge!(o::StatLearn, o2::StatLearn)
    o.n += o2.n
    γ = nobs(o2) / nobs(o)
    smooth!(o.β, o2.β, γ)
    merge!(o.alg, o2.alg, γ)
    smooth!(o.λ, o2.λ, γ)
end

predict(o::StatLearn, x::VectorOb{Number}) = dot(x, o.β)
predict(o::StatLearn, x::AbstractMatrix) = x * o.β
classify(o::StatLearn, x) = sign.(predict(o, x))

function objective(o::StatLearn, x::AbstractMatrix, y::VectorOb{Number})
    mean(o.loss.(y, predict(o,x))) + sum(o.λ .* o.penalty.(o.β))
end

#-----------------------------------------------------------------------# updateβ!
function updateβ!(o::StatLearn{SGD}, γ)
    for j in eachindex(o.β)
        o.β[j] = prox(o.penalty, o.β[j] - γ * o.gx[j], γ * o.λ[j])
    end
end
function updateβ!(o::StatLearn{T}, γ) where {T<:Union{ADAGRAD, RMSPROP}}
    for j in eachindex(o.β)
        s = γ / sqrt(o.alg.h[j] + ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - s * o.gx[j], s * o.λ[j])
    end
end
function updateβ!(o::StatLearn{ADAM}, γ)
    for j in eachindex(o.β)
        s = γ / sqrt(o.alg.v[j] + ϵ)
        o.β[j] = prox(o.penalty, o.β[j] - s * o.alg.m[j], s * o.λ[j])
    end
end
function updateβ!(o::StatLearn{ADAMAX}, γ)
    for j in eachindex(o.β)
        s = γ / ((1 - o.alg.β1^nobs(o)) * o.alg.v[j])
        o.β[j] = prox(o.penalty, o.β[j] - s * o.alg.m[j], s * o.λ[j])
    end
end
function updateβ!(o::StatLearn{ADADELTA}, γ)
    for j in eachindex(o.β)
        s = o.alg.δ[j]
        o.β[j] = prox(o.penalty, o.β[j] - s * o.gx[j], s * o.λ[j])
    end
end

#------------------------------------------------------------------# Majorization-based
# lipschitz_constant (L): f(θ) ≤ f(x) + ∇f(x)'(θ - x) + (L / 2) ||θ - x||^2
lconst(loss, x, y) = error("Unkown Lipschitz constant for loss $loss")

lconst(o::typeof(l2regloss), x, y) = dot(x, x)

lconst(o::typeof(logisticloss), x, y) = .25 * dot(x, x)

lconst(o::DWDLoss, x, y) = (o.q + 1)^2 / o.q * dot(x, x)

#-----------------------------------------------------------------------# OMAS
# L stored in o.alg.a[1]
function _fit!(o::StatLearn{OMAS}, xy)
    x, y = xy
    (o.n += 1) == 1  && init!(o, length(x))
    γ = o.rate(o.n)
    b = o.alg.b
    gradient!(o, x, y)
    ht = lconst(o.loss, x, y)
    L = (o.alg.a[1] = smooth(o.alg.a[1], ht, γ))
    for j in eachindex(o.β)
        b[j] = smooth(b[j], ht * o.β[j] - o.gx[j], γ)
        o.β[j] = prox(o.penalty, b[j] / L, o.λ[j] / L)
    end
end
#-----------------------------------------------------------------------# OMAP
function _fit!(o::StatLearn{OMAP}, xy)
    x, y = xy
    (o.n += 1) == 1 && init!(o, length(x))
    γ = o.rate(o.n)
    gradient!(o, x, y)
    h_inv = inv(lconst(o.loss, x, y))
    for j in eachindex(o.β)
        o.β[j] -= γ * h_inv * o.gx[j]
    end
end
#-----------------------------------------------------------------------# MSPI
function _fit!(o::StatLearn{MSPI}, xy)
    x, y = xy
    (o.n += 1) == 1  && init!(o, length(x))
    γ = o.rate(o.n)
    gradient!(o, x, y)
    γ2 = γ / (1 + γ * lconst(o.loss, x, y))
    for j in eachindex(o.β)
        @inbounds o.β[j] = prox(o.penalty, o.β[j] - γ2 * o.gx[j], γ2 * o.λ[j])
    end
end
