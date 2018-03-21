abstract type Algorithm end 
Base.copy(o::Algorithm) = deepcopy(o)
init!(o::Algorithm, p) = o
update!(o::Algorithm, gx) = nothing
Base.merge!(o::T, o2::T, γ) where {T<:Algorithm} = o

abstract type SGAlgorithm <: Algorithm end

#-----------------------------------------------------------------------# SGD
struct SGD <: SGAlgorithm end

#-----------------------------------------------------------------------# ADAGRAD 
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
mutable struct RMSPROP <: SGAlgorithm
    α::Float64
    h::Vector{Float64}
    RMSPROP(α = .9, p = 0) = new(α, zeros(p))
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

# #-----------------------------------------------------------------------# ADADELTA 
# mutable struct ADADELTA <: SGAlgorithm 
#     v::Vector{Float64}
#     Δ::Vector{Float64}
#     ρ::Float64
#     ADADELTA(ρ = .95) = new(Float64[], Float64[], ρ)
# end
# init!(o::ADADELTA, p) = (o.v = zeros(p); o.Δ = zeros(p))
# function Base.merge!(o::ADADELTA, o2::ADADELTA, γ)
#     smooth!(o.v, o2.v, γ)
#     smooth!(o.Δ, o2.Δ, γ)
#     o.ρ = smooth(o.ρ, o2.ρ, γ)
#     o
# end

#-----------------------------------------------------------------------# ADAM 
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


# #-----------------------------------------------------------------------# ADAM 

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