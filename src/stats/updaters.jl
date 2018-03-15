#-----------------------------------------------------------------------# Updater
abstract type Updater end

Base.show(io::IO, u::Updater) = print(io, name(u, false, false))
Base.merge!(o::T, o2::T, γ::Float64) where {T <: Updater} = warn("$T can't be merged.")

init(u::Updater, p) = u
init(typ, u::Updater, p) = init(u, p)

#-----------------------------------------------------------------------# SGUpdater
abstract type SGUpdater <: Updater end

# function update!(θ::Vector, gx::Vector, γ::Float64, u::SGUpdater)
#     for i in eachindex(θ)
#         @inbounds θ[i] = update(θ[i], gx[i], γ, u)
#     end
# end


#-----------------------------------------------------------------------# SGD
"""
    SGD()

Stochastic gradient descent.
"""
struct SGD <: SGUpdater end
Base.merge!(a::SGD, b::SGD, γ::Float64) = a
# update(θ::Number, gx::Number, γ::Float64, ::SGD) = θ -= γ * gx

#-----------------------------------------------------------------------# NSGD
"""
    NSGD(α)

Nesterov accelerated Proximal Stochastic Gradient Descent.
"""
struct NSGD <: SGUpdater
    α::Float64
    v::Vector{Float64}
    θ::Vector{Float64}
    NSGD(α = 0.0, p = 0) = new(α, zeros(p), zeros(p))
end
init(u::NSGD, p::Int) = NSGD(u.α, p)
function Base.merge!(o::NSGD, o2::NSGD, γ::Float64)
    o.α == o2.α || error("Merge Failed.  NSGD objects use different α.")
    smooth!(o.v, o2.v, γ)
    smooth!(o.θ, o2.θ, γ)
end

#-----------------------------------------------------------------------# ADAGRAD
"""
    ADAGRAD()

Adaptive (element-wise learning rate) stochastic gradient descent.
"""
mutable struct ADAGRAD <: SGUpdater
    h::Vector{Float64}
    nobs::Int
    ADAGRAD(p = 0) = new(zeros(p), 0)
end
init(u::ADAGRAD, p) = ADAGRAD(p)
function Base.merge!(o::ADAGRAD, o2::ADAGRAD, γ::Float64)
    o.nobs += o2.nobs
    smooth!(o.h, o2.h, γ)
    o
end
# function update!(θ::Vector, g::Vector, γ::Float64, u::ADAGRAD)
#     u.nobs += 1
#     w = 1 / u.nobs
#     @inbounds for i in eachindex(θ)
#         u.h[i] = smooth(u.h[i], g[i] ^ 2, w)
#         s = γ * inv(sqrt(u.h[i] + ϵ))
#         o.β[j] = prox(o.penalty, o.β[j] - s * o.gx[j], s * o.λfactor[j])
#     end
# end

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
init(u::ADADELTA, p) = ADADELTA(u.ρ, p)
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
init(u::RMSPROP, p) = RMSPROP(u.α, p)
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
    M::Vector{Float64}
    V::Vector{Float64}
    nups::Int
    function ADAM(β1::Float64 = 0.99, β2::Float64 = .999, p::Integer = 0)
        @assert 0 < β1 < 1
        @assert 0 < β2 < 1
        new(β1, β2, zeros(p), zeros(p), 0)
    end
end
init(u::ADAM, p) = ADAM(u.β1, u.β2, p)
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
    M::Vector{Float64}
    V::Vector{Float64}
    nups::Int
    function ADAMAX(β1::Float64 = 0.9, β2::Float64 = .999, p::Integer = 0)
        @assert 0 < β1 < 1
        @assert 0 < β2 < 1
        new(β1, β2, zeros(p), zeros(p), 0)
    end
end
init(u::ADAMAX, p) = ADAMAX(u.β1, u.β2, p)
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
    M::Vector{Float64}
    V::Vector{Float64}
    nups::Int
    function NADAM(β1::Float64 = 0.99, β2::Float64 = .999, p::Integer = 0)
        @assert 0 < β1 < 1
        @assert 0 < β2 < 1
        new(β1, β2, zeros(p), zeros(p), 0)
    end
end
init(u::NADAM, p) = NADAM(u.β1, u.β2, p)
function Base.merge!(o::NADAM, o2::NADAM, γ::Float64)
    (o.β1 == o2.β1) && (o.β2 == o2.β2) ||
        error("Merge failed.  NADAM objects use different momentum parameters.")
    o.nups += o2.nups 
    smooth!(o.M, o2.M, γ)
    smooth!(o.V, o2.V, γ)
end

#-----------------------------------------------------------------------# MSPI, OMAS, OMAP
for T in [:OMAS, :OMAS2, :OMAP, :OMAP2, :MSPI, :MSPI2]
    @eval begin
        """
            MSPI()  # Majorized stochastic proximal iteration
            MSPI2()
            OMAS()  # Online MM - Averaged Surrogate
            OMAS2()
            OMAP()  # Online MM - Averaged Parameter
            OMAP2()

        Updaters based on majorizing functions.  `MSPI`/`OMAS`/`OMAP` define a family of 
        algorithms and not a specific update, thus each type has two possible versions.

        - See https://arxiv.org/abs/1306.4650 for OMAS
        - Ask @joshday for details on OMAP and MSPI
        """
        struct $T{T} <: Updater
            buffer::T 
        end
        $T() = $T(nothing)
        function Base.merge!(a::S, b::S, γ::Float64) where {S <: $T} 
            smooth!.(a.buffer, b.buffer, γ)
            a
        end
    end 
end