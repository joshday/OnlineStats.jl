abstract type Algorithm end 
Base.copy(o::Algorithm) = deepcopy(o)
init!(o::Algorithm, p) = o
update!(o::Algorithm, gx) = nothing
Base.merge!(o::T, o2::T, γ) where {T<:Algorithm} = o

abstract type SGAlgorithm <: Algorithm end

#-----------------------------------------------------------------------# SGD
"""
    SGD()
"""
struct SGD <: SGAlgorithm end

# #-----------------------------------------------------------------------# NSGD
# """
#     NSGD(α)

# Nesterov accelerated Proximal Stochastic Gradient Descent.
# """
# struct NSGD <: SGUpdater
#     α::Float64
#     v::Vector{Float64}
#     θ::Vector{Float64}
#     NSGD(α = 0.0, p = 0) = new(α, zeros(p), zeros(p))
# end
# init(u::NSGD, p::Int) = NSGD(u.α, p)
# function Base.merge!(o::NSGD, o2::NSGD, γ::Float64)
#     o.α == o2.α || error("Merge Failed.  NSGD objects use different α.")
#     smooth!(o.v, o2.v, γ)
#     smooth!(o.θ, o2.θ, γ)
# end

#-----------------------------------------------------------------------# ADAGRAD 
"""
    ADAGRAD()
"""
mutable struct ADAGRAD <: SGAlgorithm 
    h::Vector{Float64}
    n::Int
    ADAGRAD() = new(zeros(0), 0)
end
init!(o::ADAGRAD, p) = (o.h = zeros(p))
Base.merge!(o::ADAGRAD, o2::ADAGRAD, γ) = (smooth!(o.h, o2.h, γ); o)
function update!(o::ADAGRAD, gx)
    o.n += 1
    for j in eachindex(o.h)
        o.h[j] = smooth(o.h[j], gx[j]^2, 1 / o.n)
    end
end

#-----------------------------------------------------------------------# RMSPROP
"""
    RMSPROP(α = .9)
"""
mutable struct RMSPROP <: SGAlgorithm
    α::Float64
    h::Vector{Float64}
    RMSPROP(α = .9) = new(α, zeros(0))
end
init!(a::RMSPROP, p) = (a.h = zeros(p))
function Base.merge!(o::RMSPROP, o2::RMSPROP, γ)
    o.α = smooth(o.α, o2.α, γ)
    smooth!(o.h, o2.h, γ)
end
function update!(o::RMSPROP, gx)
    for j in eachindex(o.h)
        o.h[j] = smooth(gx[j]^2, o.h[j], o.α)
    end
end

#-----------------------------------------------------------------------# ADADELTA 
mutable struct ADADELTA <: SGAlgorithm 
    v::Vector{Float64}
    Δ::Vector{Float64}
    δ::Vector{Float64}
    ρ::Float64
    ADADELTA(ρ = .95) = new(Float64[], Float64[], Float64[], ρ)
end
init!(o::ADADELTA, p) = (o.v = zeros(p); o.δ = zeros(p); o.Δ = zeros(p))
function Base.merge!(o::ADADELTA, o2::ADADELTA, γ)
    smooth!(o.v, o2.v, γ)
    smooth!(o.Δ, o2.Δ, γ)
    o.ρ = smooth(o.ρ, o2.ρ, γ)
    o
end
function update!(o::ADADELTA, gx)
    for j in eachindex(o.v)
        g2 = gx[j] ^ 2
        o.v[j] = smooth(g2 + ϵ, o.v[j], o.ρ)
        o.δ[j] = sqrt(o.Δ[j] / o.v[j] + ϵ)  # not multiplied by gx[j] as in paper
        o.Δ[j] = smooth(o.δ[j]^2 * g2, o.Δ[j], o.ρ)
    end
end

#-----------------------------------------------------------------------# ADAM 
"""
    ADAM(β1 = .99, β2 = .999)
"""
mutable struct ADAM <: SGAlgorithm 
    m::Vector{Float64}
    v::Vector{Float64}
    β1::Float64 
    β2::Float64
    ADAM(β1 = .99, β2 = .999) = new(Float64[], Float64[], β1, β2)
end
init!(o::ADAM, p) = (o.m = zeros(p); o.v = zeros(p))
function Base.merge!(o::ADAM, o2::ADAM, γ)
    smooth!(o.m, o2.m, γ)
    smooth!(o.v, o2.v, γ)
    o.β1 = smooth(o.β1, o2.β1, γ)
    o.β2 = smooth(o.β2, o2.β2, γ)
    o
end
function update!(o::ADAM, gx)
    for j in eachindex(o.m)
        g = gx[j]
        o.m[j] = smooth(g, o.m[j], o.β1)
        o.v[j] = smooth(g * g, o.v[j], o.β2)
    end
end

#-----------------------------------------------------------------------# ADAMAX
"""
    ADAMAX(η, β1 = .9, β2 = .999)

ADAMAX with momentum parameters `β1`, `β2`
"""
mutable struct ADAMAX <: SGAlgorithm
    β1::Float64
    β2::Float64
    m::Vector{Float64}
    v::Vector{Float64}
    function ADAMAX(β1::Float64 = 0.9, β2::Float64 = .999)
        @assert 0 < β1 < 1
        @assert 0 < β2 < 1
        new(β1, β2, zeros(0), zeros(0))
    end
end
init!(o::ADAMAX, p) = (o.m = zeros(p); o.v = zeros(p))
function Base.merge!(o::ADAMAX, o2::ADAMAX, γ)
    smooth!(o.m, o2.m, γ)
    smooth!(o.v, o2.v, γ)
    o.β1 = smooth(o.β1, o2.β1, γ)
    o.β2 = smooth(o.β2, o2.β2, γ)
    o
end
function update!(o::ADAMAX, gx)
    for j in eachindex(o.m)
        o.m[j] = smooth(gx[j], o.m[j], o.β1)
        o.v[j] = max(abs(gx[j]) + ϵ, o.β2 * o.v[j])
    end
end

# #-----------------------------------------------------------------------# NADAM
# """
#     NADAM(α1 = .99, α2 = .999)

# Adaptive Moment Estimation with momentum parameters `α1` and `α2`.
# """
# mutable struct NADAM <: SGUpdater
#     β1::Float64
#     β2::Float64
#     M::Vector{Float64}
#     V::Vector{Float64}
#     nups::Int
#     function NADAM(β1::Float64 = 0.99, β2::Float64 = .999, p::Integer = 0)
#         @assert 0 < β1 < 1
#         @assert 0 < β2 < 1
#         new(β1, β2, zeros(p), zeros(p), 0)
#     end
# end
# init(u::NADAM, p) = NADAM(u.β1, u.β2, p)
# function Base.merge!(o::NADAM, o2::NADAM, γ::Float64)
#     (o.β1 == o2.β1) && (o.β2 == o2.β2) ||
#         error("Merge failed.  NADAM objects use different momentum parameters.")
#     o.nups += o2.nups 
#     smooth!(o.M, o2.M, γ)
#     smooth!(o.V, o2.V, γ)
# end

#-----------------------------------------------------------------------# MSPI, OMAS, OMAP
struct MSPI <: Algorithm end

struct OMAP <: Algorithm end

mutable struct OMAS <: Algorithm  
    a::Vector{Float64}
    b::Vector{Float64}
    A::Matrix{Float64}
    B::Matrix{Float64}
    OMAS() = new(zeros(0), zeros(0), zeros(0, 0), zeros(0, 0))
end
init!(o::OMAS, p) = (o.a = zeros(p); o.b = zeros(p))
