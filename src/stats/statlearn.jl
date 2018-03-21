"""
    StatLearn(p, args...)

Fit a model that is linear in the parameters.  

The (offline) objective function that StatLearn approximately minimizes is

``(1/n) ∑ᵢ f(yᵢ, xᵢ'β) + ∑ⱼ λⱼ g(βⱼ),``

where ``fᵢ`` are loss functions of a single response and linear predictor, ``λⱼ``s are 
nonnegative regularization parameters, and ``g`` is a penalty function. 

# Arguments 

"""
mutable struct StatLearn{A<:Algorithm, L<:Loss, P<:Penalty, W} <: OnlineStat{(1, 0)}
    β::Vector{Float64}
    λ::Vector{Float64}
    gx::Vector{Float64}
    loss::L 
    penalty::P 
    alg::A
    rate::W 
    n::Int
end
function StatLearn(p::Int, args...; rate=LearningRate())
    λ, loss, pen, alg = zeros(p), .5*L2DistLoss(), NoPenalty(), SGD()
    for a in args 
        if a isa AbstractVector 
            λ = a
        elseif a isa Float64 
            λ = fill(a, 1)
        elseif a isa Loss 
            loss = a 
        elseif a isa Penalty 
            pen = a 
        elseif a isa Algorithm 
            alg = a 
        end
    end
    init!(alg, p)
    StatLearn(zeros(p), λ, zeros(p), loss, pen, alg, rate, 0)
end

function Base.show(io::IO, o::StatLearn)
    print(io, "StatLearn: ")
    print(io, name(o.alg, false, false))
    print(io, " | mean(λ)=", mean(o.λ))
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
    o.n += 1
    gradient!(o, x, y)
    update!(o.alg, o.gx)
    updateβ!(o, o.rate(o.n))
end
function Base.merge!(o::StatLearn, o2::StatLearn)
    o.n += o2.n 
    γ = nobs(o2) / nobs(o)
    smooth!(o.β, o2.β, γ)
    merge!(o.alg, o2.alg, γ)
    smooth!(o.λ, o2.λ, γ)
end

predict(o::StatLearn, x::VectorOb) = _dot(x, o.β)
predict(o::StatLearn, x::AbstractMatrix) = x * o.β
classify(o::StatLearn, x) = sign.(predict(o, x))

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




# function init!(o::StatLearn, p) 
#     init!(o.alg, p)
#     o.β = zeros(p)
#     if length(o.λ) == 0 
#         o.λ = zeros(p)
#     elseif length(o.λ) == 1 
#         o.λ = fill(o.λ[1], p)
#     elseif length(o.λ) == p 
#     else
#         Compat.@error("Size of λ is incompatible with the number of predictors.")
#     end
# end

# function _fit!(o::StatLearn{A}, xy) where {A<:SGAlgorithm}
#     x, y = xy
#     alg = o.alg
#     (alg.n += 1) == 1  && init!(o, length(x))
#     d_dη = deriv(o.loss, y, predict(o, x))
#     for j in eachindex(o.β)
#         alg.δ[j] = x[j] * d_dη
#     end
#     γ, gx = direction!(alg)
#     for j in eachindex(o.β)
#         o.β[j] = prox(o.β[j] - alg.δ[j]
#     end
# end

# predict(o::StatLearn, x::VectorOb) = _dot(x, o.β)
# predict(o::StatLearn, x::AbstractMatrix) = x * o.β
# classify(o::StatLearn, x) = sign.(predict(o, x))

# function objective(o::StatLearn, x::AbstractMatrix, y::VectorOb)
#     value(o.loss, y, predict(o, x), AvgMode.Mean()) + value(o.penalty, o.β, o.λ)
# end

# function Base.merge!(o::StatLearn{A,L,P}, o2::StatLearn{A,L,P}) where {A,L,P}
#     merge!(o.alg, o2.alg)
#     smooth!(o.β, o2.β, nobs(o2) / nobs(o))
#     smooth!(o.λ, o2.λ, nobs(o2) / nobs(o))
#     o
# end

# function statlearnpath(o::StatLearn, αs::AbstractVector{<:Real})
#     path = [copy(o) for i in 1:length(αs)]
#     for i in eachindex(αs)
#         path[i].λ .*= αs[i]
#     end
#     Series(path...)
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