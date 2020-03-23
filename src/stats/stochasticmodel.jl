#-----------------------------------------------------------------------------# losses 
module Losses 
    l2(y, xθ) = (y - xθ) ^ 2 / 2
    deriv(::typeof(l2)) = (y, xθ) -> xθ - y

    l1(y, xθ) = abs(y - xθ)
    deriv(::typeof(l1)) = (y, xθ) -> sign(xθ - y)

    struct Huber{δ} end
    huber(δ) = Huber{δ}()
    function (::Huber{δ})(y, xθ) where {δ} 
        a = abs(xθ - y)
        a < δ ? a ^ 2 / 2 : δ * (a - δ / 2)
    end
    function deriv(::Huber{δ}) where {δ}
        function (y, xθ)
            a = xθ - y
            abs(a) < δ ? a : sign(a) * δ
        end
    end
end

#-----------------------------------------------------------------------------# StochasticLM
struct StochasticLM{L, SA <: StochasticApproximation} <: OnlineStat{XY}
    alg::SA
    loss::L
end
function StochasticLM(loss = Losses.l2distloss, alg=SGD_Stat; kw...)
    function Δf!(buffer, data, θ)
        x, y = data 
        buffer .= x .* Losses.deriv(loss)(y, x'θ)
    end
    core = GradientCore(Δf!, zeros(0))
    StochasticLM(alg(XY, core), loss; kw...)
end
function Base.show(io::IO, o::StochasticLM) 
    print(io, "StochasticLM: n=$(nobs(o)) | loss=$(o.loss) | alg=$(name(o.alg, false, false)) | value=$(value(o))")
end

_fit!(o::StochasticLM, xy) = fit!(o.alg, xy)
value(o::StochasticLM) = value(o.alg)
nobs(o::StochasticLM) = nobs(o.alg)

# function StatLearn(args...; rate=LearningRate())
#     λ, loss, pen, alg = zeros(p), linregloss, zero, SGD()
#     for a in args
#         a isa AbstractVector && (λ = a)
#         a isa Float64        && (λ = fill(a, 1))
#         a isa Loss           && (loss = a)
#         a isa Penalty        && (pen = a)
#         a isa Algorithm      && (alg = a)
#     end
#     init!(alg, p)
#     StatLearn(zeros(p), λ, zeros(p), loss, pen, alg, rate, 0)
# end

# function Base.show(io::IO, o::StatLearn)
#     print(io, "StatLearn: ")
#     print(io, name(o.alg, false, false))
#     print(io, " | mean(λ)=", mean(o.λ))
#     print(io, " | ", o.loss)
#     print(io, " | ", o.penalty)
#     print(io, " | nobs=", nobs(o))
#     print(io, " | nvars=", length(o.β))
# end
# coef(o::StatLearn) = value(o)

# function gradient!(o::StatLearn, x, y)
#     d_dη = LearnBase.deriv(o.loss, y, predict(o, x))
#     for j in eachindex(o.gx)
#         o.gx[j] = x[j] * d_dη
#     end
# end
# function _fit!(o::StatLearn{<:SGAlgorithm}, xy)
#     x, y = xy
#     o.n += 1
#     gradient!(o, x, y)
#     update!(o.alg, o.gx)
#     updateβ!(o, o.rate(o.n))
# end
# function _merge!(o::StatLearn, o2::StatLearn)
#     o.n += o2.n
#     γ = nobs(o2) / nobs(o)
#     smooth!(o.β, o2.β, γ)
#     merge!(o.alg, o2.alg, γ)
#     smooth!(o.λ, o2.λ, γ)
# end

# predict(o::StatLearn, x::VectorOb) = dot(x, o.β)
# predict(o::StatLearn, x::AbstractMatrix) = x * o.β
# classify(o::StatLearn, x) = sign.(predict(o, x))

# function objective(o::StatLearn, x::AbstractMatrix, y::VectorOb)
#     LearnBase.value(o.loss, y, predict(o, x), AggMode.Mean()) + LearnBase.value(o.penalty, o.β, o.λ)
# end

# #-----------------------------------------------------------------------# updateβ!
# function updateβ!(o::StatLearn{SGD}, γ)
#     for j in eachindex(o.β)
#         o.β[j] = prox(o.penalty, o.β[j] - γ * o.gx[j], γ * o.λ[j])
#     end
# end
# function updateβ!(o::StatLearn{T}, γ) where {T<:Union{ADAGRAD, RMSPROP}}
#     for j in eachindex(o.β)
#         s = γ / sqrt(o.alg.h[j] + ϵ)
#         o.β[j] = prox(o.penalty, o.β[j] - s * o.gx[j], s * o.λ[j])
#     end
# end
# function updateβ!(o::StatLearn{ADAM}, γ)
#     for j in eachindex(o.β)
#         s = γ / sqrt(o.alg.v[j] + ϵ)
#         o.β[j] = prox(o.penalty, o.β[j] - s * o.alg.m[j], s * o.λ[j])
#     end
# end
# function updateβ!(o::StatLearn{ADAMAX}, γ)
#     for j in eachindex(o.β)
#         s = γ / ((1 - o.alg.β1^nobs(o)) * o.alg.v[j])
#         o.β[j] = prox(o.penalty, o.β[j] - s * o.alg.m[j], s * o.λ[j])
#     end
# end
# function updateβ!(o::StatLearn{ADADELTA}, γ)
#     for j in eachindex(o.β)
#         s = o.alg.δ[j]
#         o.β[j] = prox(o.penalty, o.β[j] - s * o.gx[j], s * o.λ[j])
#     end
# end


# # #-----------------------------------------------------------------------# NSGD
# # function fit!(o::StatLearn{NSGD}, t::Tuple{VectorOb, Real}, γ::Float64)
# #     U = o.updater
# #     x, y = t
# #     for j in eachindex(o.β)
# #         U.θ[j] = o.β[j] - U.α * U.v[j]
# #     end
# #     ŷ = dot(x, U.θ)
# #     for j in eachindex(o.β)
# #         U.v[j] = U.α * U.v[j] + deriv(o.loss, y, ŷ) * x[j]
# #         @inbounds o.β[j] = prox(o.penalty, o.β[j] - γ * U.v[j], γ * o.λfactor[j])
# #     end
# # end
# # #-----------------------------------------------------------------------# NADAM
# # function update!(o::StatLearn{NADAM}, γ)
# #     U = o.updater
# #     β1 = U.β1
# #     β2 = U.β2
# #     U.nups += 1
# #     @inbounds for j in eachindex(o.β)
# #         gx = o.gx[j] + deriv(o.penalty, o.β[j], o.λfactor[j])
# #         U.M[j] = smooth(gx, U.M[j], U.β1)
# #         U.V[j] = smooth(gx ^ 2, U.V[j], U.β2)
# #         mt = U.M[j] / (1 - U.β1 ^ U.nups)
# #         vt = U.V[j] / (1 - U.β2 ^ U.nups)
# #         Δ = γ / (sqrt(vt + ϵ)) * (U.β1 * mt + (1 - U.β1) / (1 - U.β1^U.nups) * gx)
# #         o.β[j] -= Δ
# #     end
# # end



# #------------------------------------------------------------------# Majorization-based
# const L2Scaled{N} = LossFunctions.ScaledDistanceLoss{L2DistLoss, N}

# # lipschitz_constant (L): f(θ) ≤ f(θₜ) + ∇f(θₜ)'(θ - θₜ) + (L / 2) ||θ - θₜ||^2
# lconst(o::StatLearn, x, y) = lconst(o.loss, x, y)

# lconst(o::Loss, x, y) = error("No defined Lipschitz constant for $o")
# lconst(o::L2Scaled{N}, x, y) where {N} = 2N * dot(x, x)
# lconst(o::LossFunctions.L2DistLoss, x, y) = 2 * dot(x, x)
# lconst(o::LossFunctions.LogitMarginLoss, x, y) = .25 * dot(x, x)
# lconst(o::LossFunctions.DWDMarginLoss, x, y) = (o.q + 1)^2 / o.q * dot(x, x)

# #-----------------------------------------------------------------------# OMAS
# # L stored in o.alg.a[1]
# function _fit!(o::StatLearn{OMAS}, xy)
#     γ = o.rate(o.n += 1)
#     x, y = xy
#     b = o.alg.b
#     gradient!(o, x, y)
#     ht = lconst(o.loss, x, y)
#     L = (o.alg.a[1] = smooth(o.alg.a[1], ht, γ))
#     for j in eachindex(o.β)
#         b[j] = smooth(b[j], ht * o.β[j] - o.gx[j], γ)
#         o.β[j] = prox(o.penalty, b[j] / L, o.λ[j] / L)
#     end
# end
# #-----------------------------------------------------------------------# OMAP
# function _fit!(o::StatLearn{OMAP}, xy)
#     γ = o.rate(o.n += 1)
#     x, y = xy
#     gradient!(o, x, y)
#     h_inv = inv(lconst(o, x, y))
#     for j in eachindex(o.β)
#         o.β[j] -= γ * h_inv * o.gx[j]
#     end
# end
# #-----------------------------------------------------------------------# MSPI
# function _fit!(o::StatLearn{MSPI}, xy)
#     γ = o.rate(o.n += 1)
#     x, y = xy
#     gradient!(o, x, y)
#     γ2 = γ / (1 + γ * lconst(o, x, y))
#     for j in eachindex(o.β)
#         @inbounds o.β[j] = prox(o.penalty, o.β[j] - γ2 * o.gx[j], γ2 * o.λ[j])
#     end
# end
