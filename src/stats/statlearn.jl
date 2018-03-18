# #-----------------------------------------------------------------------------# StatLearn
# doc"""
#     StatLearn(p::Int, args...)

# Fit a statistical learning model of `p` independent variables for a given `loss`, `penalty`, and `λ`.  Additional arguments can be given in any order (and is still type stable):

# - `loss = .5 * L2DistLoss()`: any Loss from LossFunctions.jl
# - `penalty = L2Penalty()`: any Penalty (which has a `prox` method) from PenaltyFunctions.jl.
# - `λ = fill(.1, p)`: a Vector of element-wise regularization parameters
# - `updater = SGD()`: [`SGD`](@ref), [`ADAGRAD`](@ref), [`ADAM`](@ref), [`ADAMAX`](@ref), [`MSPI`](@ref)

# # Details

# The (offline) objective function that StatLearn approximately minimizes is

# ``\frac{1}{n}\sum_{i=1}^n f_i(\beta) + \sum_{j=1}^p \lambda_j g(\beta_j),``

# where the ``f_i``'s are loss functions evaluated on a single observation, ``g`` is a penalty function, and the ``\lambda_j``s are nonnegative regularization parameters.

# # Example
#     using LossFunctions, PenaltyFunctions
#     x = randn(100_000, 10)
#     y = x * linspace(-1, 1, 10) + randn(100_000)
#     o = StatLearn(10, .5 * L2DistLoss(), L1Penalty(), fill(.1, 10), SGD())
#     s = Series(o)
#     fit!(s, x, y)
#     coef(o)
#     predict(o, x)
# """
# struct StatLearn{U <: Updater, L <: Loss, P <: Penalty} <: StochasticStat{(1, 0)}
#     β::Vector{Float64}
#     gx::Vector{Float64}        # buffer for gradient
#     λfactor::Vector{Float64}
#     loss::L
#     penalty::P
#     updater::U
# end
# function StatLearn{V,L,P,U}(p::Integer, t::Tuple{V,L,P,U})
#     λf, loss, penalty, updater = t
#     length(λf) == p || throw(DimensionMismatch("lengths of λfactor and β differ"))
#     StatLearn(zeros(p), zeros(p), λf, loss, penalty, init(StatLearn, updater, p))
# end

# d(p::Integer) = (fill(.1, p), L2DistLoss(), L2Penalty(), SGD())

# a(argu::Vector{Float64}, t) = (argu, t[2], t[3], t[4])
# a(argu::Loss,            t) = (t[1], argu, t[3], t[4])
# a(argu::Penalty,         t) = (t[1], t[2], argu, t[4])
# a(argu::Updater,         t) = (t[1], t[2], t[3], argu)

# StatLearn(p::Integer)                 = StatLearn(p, d(p))
# StatLearn(p::Integer, a1)             = StatLearn(p, a(a1, d(p)))
# StatLearn(p::Integer, a1, a2)         = StatLearn(p, a(a2, a(a1, d(p))))
# StatLearn(p::Integer, a1, a2, a3)     = StatLearn(p, a(a3, a(a2, a(a1, d(p)))))
# StatLearn(p::Integer, a1, a2, a3, a4) = StatLearn(p, a(a4, a(a3, a(a2, a(a1, d(p))))))

# function Base.show(io::IO, o::StatLearn)
#     println(io, name(o))
#     print(io,   "    > β       : "); showcompact(io, o.β);        println(io)
#     if !(o.penalty isa NoPenalty)
#         print(io,   "    > λfactor : "); showcompact(io, o.λfactor);  println(io)
#     end
#     println(io, "    > Loss    : $(o.loss)")
#     println(io, "    > Penalty : $(o.penalty)")
#     print(io,   "    > Updater : $(o.updater)")
# end

# coef(o::StatLearn) = o.β

# predict(o::StatLearn, x::VectorOb) = _dot(x, o.β)
# predict(o::StatLearn, x::AbstractMatrix, ::Rows = Rows()) = x * o.β
# predict(o::StatLearn, x::AbstractMatrix, ::Cols) = x'o.β

# classify(o::StatLearn, x) = sign(predict(o, x))
# classify(o::StatLearn, x::AbstractMatrix, dim = Rows()) = sign.(predict(o, x, dim))

# loss(o::StatLearn, x, y, dim = Rows()) = value(o.loss, y, predict(o, x, dim), AvgMode.Mean())

# function value(o::StatLearn, x, y, dim = Rows())
#     value(o.loss, y, predict(o, x, dim), AvgMode.Mean()) + value(o.penalty, o.β, o.λfactor)
# end

# function statlearnpath(o::StatLearn, αs::AbstractVector{<:Real})
#     path = [copy(o) for i in 1:length(αs)]
#     for i in eachindex(αs)
#         path[i].λfactor .*= αs[i]
#     end
#     path
# end

# # Hacks to allow Tuples/NamedTuples
# _dot(x::AbstractVector, β) = dot(x, β)
# function _dot(x::VectorOb, β)
#     out = 0.0
#     for (xi, βi) in zip(x, β)
#         out += xi * βi
#     end
#     return out
# end

# # t is Tuple or NamedTuple: (x, y)
# function gradient!(o::StatLearn, t)
#     x, y = t
#     xβ = _dot(x, o.β)
#     g = deriv(o.loss, y, xβ)
#     gx = o.gx
#     for i in eachindex(gx)
#         @inbounds gx[i] = g * x[i]
#     end
# end

# function fit!(o::StatLearn{<:SGUpdater}, t::Tuple, γ::Float64)
#     gradient!(o, t)
#     update!(o, γ)
# end

# function Base.merge!(o::T, o2::T, γ::Float64) where {T <: StatLearn}
#     o.λfactor == o2.λfactor || error("Merge failed. StatLearn objects have different λs.")
#     merge!(o.updater, o2.updater, γ)
#     smooth!(o.β, o2.β, γ)
# end

# #-----------------------------------------------------------------------# SGD
# function update!(o::StatLearn{SGD}, γ)
#     for j in eachindex(o.β)
#         @inbounds o.β[j] = prox(o.penalty, o.β[j] - γ * o.gx[j], γ * o.λfactor[j])
#     end
# end
# #-----------------------------------------------------------------------# NSGD
# function fit!(o::StatLearn{NSGD}, t::Tuple{VectorOb, Real}, γ::Float64)
#     U = o.updater
#     x, y = t
#     for j in eachindex(o.β)
#         U.θ[j] = o.β[j] - U.α * U.v[j]
#     end
#     ŷ = _dot(x, U.θ) 
#     for j in eachindex(o.β)
#         U.v[j] = U.α * U.v[j] + deriv(o.loss, y, ŷ) * x[j]
#         @inbounds o.β[j] = prox(o.penalty, o.β[j] - γ * U.v[j], γ * o.λfactor[j])
#     end
# end
# #-----------------------------------------------------------------------# ADAGRAD
# function update!(o::StatLearn{ADAGRAD}, γ)
#     U = o.updater
#     U.nobs += 1
#     @inbounds for j in eachindex(o.β)
#         U.h[j] = smooth(U.h[j], o.gx[j] ^ 2, 1 / U.nobs)
#         s = γ * inv(sqrt(U.h[j] + ϵ))
#         o.β[j] = prox(o.penalty, o.β[j] - s * o.gx[j], s * o.λfactor[j])
#     end
# end
# #-----------------------------------------------------------------------# ADADELTA
# function update!(o::StatLearn{ADADELTA}, γ)
#     U = o.updater
#     ϵ = .0001
#     for j in eachindex(o.β)
#         U.g[j] = smooth(o.gx[j]^2, U.g[j], U.ρ)
#         Δβ = sqrt(U.Δβ[j] + ϵ) / sqrt(U.g[j] + ϵ) * o.gx[j]
#         o.β[j] -= Δβ
#         U.Δβ[j] = smooth(Δβ^2, U.Δβ[j], U.ρ)
#     end
# end
# #-----------------------------------------------------------------------# RMSPROP
# function update!(o::StatLearn{RMSPROP}, γ)
#     U = o.updater
#     for j in eachindex(o.β)
#         U.g[j] = U.α * U.g[j] + (1 - U.α) * o.gx[j]^2
#         o.β[j] -= γ * o.gx[j] / sqrt(U.g[j] + ϵ)
#     end
# end

# #-----------------------------------------------------------------------# ADAM
# function update!(o::StatLearn{ADAM}, γ)
#     U = o.updater
#     β1 = U.β1
#     β2 = U.β2
#     U.nups += 1
#     s = γ * sqrt(1 - β2 ^ U.nups) / (1 - β1 ^ U.nups)
#     @inbounds for j in eachindex(o.β)
#         gx = o.gx[j] + deriv(o.penalty, o.β[j], o.λfactor[j])
#         U.M[j] = smooth(gx, U.M[j], U.β1)
#         U.V[j] = smooth(gx ^ 2, U.V[j], U.β2)
#         o.β[j] -= s * U.M[j] / (sqrt(U.V[j]) + ϵ)
#     end
# end

# #-----------------------------------------------------------------------# ADAMAX
# function update!(o::StatLearn{ADAMAX}, γ)
#     U = o.updater
#     U.nups += 1
#     s = γ * sqrt(1 - U.β2 ^ U.nups) / (1 - U.β1 ^ U.nups)
#     @inbounds for j in eachindex(o.β)
#         gx = o.gx[j] + deriv(o.penalty, o.β[j], o.λfactor[j])
#         U.M[j] = smooth(gx, U.M[j], U.β1)
#         U.V[j] = max(U.β2 * U.V[j], abs(gx))
#         o.β[j] -= s * (U.M[j] / (1 - U.β1 ^ U.nups)) / (U.V[j] + ϵ)
#     end
# end

# #-----------------------------------------------------------------------# NADAM
# function update!(o::StatLearn{NADAM}, γ)
#     U = o.updater
#     β1 = U.β1
#     β2 = U.β2
#     U.nups += 1
#     @inbounds for j in eachindex(o.β)
#         gx = o.gx[j] + deriv(o.penalty, o.β[j], o.λfactor[j])
#         U.M[j] = smooth(gx, U.M[j], U.β1)
#         U.V[j] = smooth(gx ^ 2, U.V[j], U.β2)
#         mt = U.M[j] / (1 - U.β1 ^ U.nups)
#         vt = U.V[j] / (1 - U.β2 ^ U.nups)
#         Δ = γ / (sqrt(vt + ϵ)) * (U.β1 * mt + (1 - U.β1) / (1 - U.β1^U.nups) * gx)
#         o.β[j] -= Δ
#     end
# end



# #------------------------------------------------------------------# Majorization-based
# const L2Scaled{N} = LossFunctions.ScaledDistanceLoss{L2DistLoss, N}

# # f(θ) ≤ f(θₜ) + ∇f(θₜ)'(θ - θₜ) + (L / 2) ||θ - θₜ||^2
# # lipschitz_constant
# lconst(o::StatLearn, x, y) = lconst(o.loss, x, y)

# lconst(o::Loss, x, y) = error("No defined Lipschitz constant for $o")
# lconst(o::L2Scaled{N}, x, y) where {N} = 2N * _dot(x, x)
# lconst(o::L2DistLoss, x, y) = 2 * _dot(x, x)
# lconst(o::LogitMarginLoss, x, y) = .25 * _dot(x, x)
# lconst(o::DWDMarginLoss, x, y) = (o.q + 1)^2 / o.q * _dot(x, x)

# #-----------------------------------------------------------------------# OMAS
# init(StatLearn, u::OMAS, p::Int) = OMAS(zeros(p + 1))  # buffer[end] = h
# function fit!(o::StatLearn{<:OMAS}, t::Tuple{VectorOb, Real}, γ::Float64)
#     x, y = t
#     B = o.updater.buffer
#     gradient!(o, t)
#     ht = lconst(o, x, y)
#     B[end] = smooth(B[end], ht, γ)
#     h = B[end]
#     for j in eachindex(o.β)
#         B[j] = smooth(B[j], ht * o.β[j] - o.gx[j], γ)
#         o.β[j] = B[j] / h
#     end
# end
# #-----------------------------------------------------------------------# OMAP
# function fit!(o::StatLearn{<:OMAP}, t::Tuple{VectorOb, Real}, γ::Float64)
#     x, y = t
#     gradient!(o, t)
#     h_inv = inv(lconst(o, x, y))
#     for j in eachindex(o.β)
#         o.β[j] -= γ * h_inv * o.gx[j]
#     end
# end
# #-----------------------------------------------------------------------# MSPI
# function fit!(o::StatLearn{<:MSPI}, t::Tuple{VectorOb, Real}, γ::Float64)
#     gradient!(o, t)
#     x, y = t
#     denom = inv(1 + γ * lconst(o, x, y))
#     for j in eachindex(o.β)
#         @inbounds o.β[j] -= γ * denom * o.gx[j]
#     end
# end