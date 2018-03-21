abstract type Algorithm end 
nobs(o::Algorithm) = o.n
init!(o::Algorithm, p) = o
Base.merge!(o::T, o2::T, γ) where {T<:Algorithm} = o

abstract type SGAlgorithm <: Algorithm end

#-----------------------------------------------------------------------# SGD
struct SGD <: SGAlgorithm end

#-----------------------------------------------------------------------# ADAGRAD 
mutable struct ADAGRAD <: SGAlgorithm 
    h::Vector{Float64}
    ADAGRAD() = new(zeros(0))
end
init!(o::ADAGRAD, p) = (o.h = zeros(p))
Base.merge!(o::ADAGRAD, o2::ADAGRAD, γ) = (smooth!(o.h, o2.h, γ); o)

#-----------------------------------------------------------------------# MSPI 
struct MSPI <: SGAlgorithm end

#-----------------------------------------------------------------------# OMAS
mutable struct OMAS <: Algorithm 
    a::Vector{Float64}
    b::Vector{Float64}
    OMAS() = new(zeros(0), zeros(0))
end
init!(o::OMAS, p) = (o.a = zeros(p); o.b = zeros(p))
function Base.merge!(o::OMAS, o2::OMAS, γ) 
    smooth!(o.a, o2.a, γ)
    smooth!(o.b, o2.b, γ)
    o 
end

#-----------------------------------------------------------------------#  old
# init!(o::SGD, p) = (o.δ = zeros(p))

# γ, g = direction!(o)
# γ, gx = weight_direction(o)

# function direction!(o::SGD) 
#     γ = o.weight(o.n)
#     for i in eachindex(o.δ)
#         o.δ[i] = γ * o.δ[i]
#     end
# end
# Base.merge!(o::SGD, o2::SGD) = (o.n += o2.n; o)

# #-----------------------------------------------------------------------# ADAGRAD 
# mutable struct ADAGRAD{W} <: SGAlgorithm 
#     δ::Vector{Float64}
#     weight::W 
#     n::Int
#     h::Vector{Float64}
# end
# ADAGRAD(p=0; rate=LearningRate()) = ADAGRAD(zeros(p), rate, 0, zeros(p))
# init!(o::ADAGRAD, p) = (o.δ = zeros(p); o.h = zeros(p))
# function direction!(o::ADAGRAD)
#     γ = o.weight(o.n)
#     for i in eachindex(o.h)
#         o.h[i] = smooth(o.h[i], o.δ[i] ^ 2, γ)
#         o.δ[i] = γ * o.δ[i] / (o.h[i] + ϵ)
#     end
# end
# function Base.merge!(o::ADAGRAD, o2::ADAGRAD)
#     o.n += o2.n 
#     smooth!(o.h, o2.h, nobs(o2) / nobs(o))
#     o
# end

# #-----------------------------------------------------------------------# ADADELTA 
# mutable struct ADADELTA{W} <: SGAlgorithm 
#     δ::Vector{Float64}
#     weight::W 
#     n::Int 
#     v::Vector{Float64}
#     Δ::Vector{Float64}
#     ρ::Float64
# end
# ADADELTA(p=0; rate=LearningRate(), ρ = .95) = ADADELTA(zeros(p), rate, 0, zeros(p), zeros(p), ρ)
# init!(o::ADADELTA, p) = (o.δ = zeros(p); o.v = zeros(p); o.Δ = zeros(p))
# function direction!(o::ADADELTA)
#     for i in eachindex(o.δ)
#         g = o.δ[i]
#         o.v[i] = smooth(g * g, o.v[i], o.ρ)
#         Δi = (sqrt(o.Δ[i]) + ϵ) / (sqrt(o.v[i]) + ϵ)
#         o.δ[i] *= Δi
#         o.Δ[i] = smooth(Δi * Δi, o.Δ[i], o.ρ)
#     end
# end

# #-----------------------------------------------------------------------# ADAM 
# mutable struct ADAM{W} <: SGAlgorithm 
#     δ::Vector{Float64}
#     weight::W 
#     n::Int
#     m::Vector{Float64}
#     v::Vector{Float64}
#     β1::Float64 
#     β2::Float64
# end
# function ADAM(p=0; rate=LearningRate(), β1 = .99, β2 = .999)
#     ADAM(zeros(p), rate, 0, zeros(p), zeros(p), β1, β2)
# end
# init!(o::ADAM, p) = (o.δ = zeros(p); o.m = zeros(p); o.v = zeros(p))
# function direction!(o::ADAM)
#     γ = o.weight(o.n)
#     s = γ * sqrt(1 - o.β2 ^ o.n) / (1 - o.β1 ^ o.n)
#     for i in eachindex(o.δ)
#         gi = o.δ[i]
#         o.m[i] = smooth(gi,      o.m[i], o.β1)
#         o.v[i] = smooth(gi * gi, o.v[i], o.β2)
#         o.δ[i] = s * o.m[i] / (sqrt(o.v[i]) + ϵ)
#     end
# end
# function Base.merge!(o::ADAM, o2::ADAM)
#     o.n += o2.n 
#     smooth!(o.m, o2.m, nobs(o2) / nobs(o))
#     smooth!(o.v, o2.v, nobs(o2) / nobs(o))
#     o
# end

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

# #-----------------------------------------------------------------------# ADADELTA
# """
#     ADADELTA(ρ = .95)

# ADADELTA ignores weight.
# """
# mutable struct ADADELTA <: SGUpdater
#     ρ::Float64
#     g::Vector{Float64}
#     Δβ::Vector{Float64}
#     ADADELTA(ρ = .95, p = 0) = new(ρ, zeros(p), zeros(p))
# end
# init(u::ADADELTA, p) = ADADELTA(u.ρ, p)
# function Base.merge!(o::ADADELTA, o2::ADADELTA, γ::Float64)
#     o.ρ == o2.ρ || error("Merge failed.  ADADELTA objects use different ρ.")
#     smooth!(o.g, o2.g, γ)
#     smooth!(o.Δβ, o2.Δβ, γ)
# end

# #-----------------------------------------------------------------------# RMSPROP
# """
#     RMSPROP(α = .9)
# """
# mutable struct RMSPROP <: SGUpdater
#     α::Float64
#     g::Vector{Float64}
#     RMSPROP(α = .9, p = 0) = new(α, zeros(p))
# end
# init(u::RMSPROP, p) = RMSPROP(u.α, p)
# function Base.merge!(o::RMSPROP, o2::RMSPROP, γ::Float64)
#     o.α == o2.α || error("RMSPROP objects use different α")
#     smooth!(o.g, o2.g, γ)
# end

# #-----------------------------------------------------------------------# ADAM
# """
#     ADAM(α1 = .99, α2 = .999)

# Adaptive Moment Estimation with momentum parameters `α1` and `α2`.
# """
# mutable struct ADAM <: SGUpdater
#     β1::Float64
#     β2::Float64
#     M::Vector{Float64}
#     V::Vector{Float64}
#     nups::Int
#     function ADAM(β1::Float64 = 0.99, β2::Float64 = .999, p::Integer = 0)
#         @assert 0 < β1 < 1
#         @assert 0 < β2 < 1
#         new(β1, β2, zeros(p), zeros(p), 0)
#     end
# end
# init(u::ADAM, p) = ADAM(u.β1, u.β2, p)
# function Base.merge!(o::ADAM, o2::ADAM, γ::Float64)
#     (o.β1 == o2.β1) && (o.β2 == o2.β2) ||
#         error("Merge failed.  ADAM objects use different momentum parameters.")
#     o.nups += o2.nups 
#     smooth!(o.M, o2.M, γ)
#     smooth!(o.V, o2.V, γ)
# end

# #-----------------------------------------------------------------------# ADAMAX
# """
#     ADAMAX(η, β1 = .9, β2 = .999)

# ADAMAX with step size `η` and momentum parameters `β1`, `β2`
# """
# mutable struct ADAMAX <: SGUpdater
#     β1::Float64
#     β2::Float64
#     M::Vector{Float64}
#     V::Vector{Float64}
#     nups::Int
#     function ADAMAX(β1::Float64 = 0.9, β2::Float64 = .999, p::Integer = 0)
#         @assert 0 < β1 < 1
#         @assert 0 < β2 < 1
#         new(β1, β2, zeros(p), zeros(p), 0)
#     end
# end
# init(u::ADAMAX, p) = ADAMAX(u.β1, u.β2, p)
# function Base.merge!(o::ADAMAX, o2::ADAMAX, γ::Float64)
#     (o.β1 == o2.β1) && (o.β2 == o2.β2) ||
#         error("Merge failed.  ADAMAX objects use different momentum parameters.")
#     o.nups += o2.nups 
#     smooth!(o.M, o2.M, γ)
#     smooth!(o.V, o2.V, γ)
# end

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

# #-----------------------------------------------------------------------# MSPI, OMAS, OMAP
# for T in [:OMAS, :OMAS2, :OMAP, :OMAP2, :MSPI, :MSPI2]
#     @eval begin
#         """
#             MSPI()  # Majorized stochastic proximal iteration
#             MSPI2()
#             OMAS()  # Online MM - Averaged Surrogate
#             OMAS2()
#             OMAP()  # Online MM - Averaged Parameter
#             OMAP2()

#         Updaters based on majorizing functions.  `MSPI`/`OMAS`/`OMAP` define a family of 
#         algorithms and not a specific update, thus each type has two possible versions.

#         - See https://arxiv.org/abs/1306.4650 for OMAS
#         - Ask @joshday for details on OMAP and MSPI
#         """
#         struct $T{T} <: Algorithm
#             buffer::T 
#         end
#         $T() = $T(nothing)
#         function Base.merge!(a::S, b::S) where {S <: $T} 

#             smooth!.(a.buffer, b.buffer, γ)
#             a
#         end
#     end 
# end