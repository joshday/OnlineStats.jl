mutable struct NormalMix <: DistributionStat{ScalarIn}
    s1::VecF
    s2::VecF
    s3::VecF
    w::VecF
    μ::VecF
    σ2::VecF
    function NormalMix(k::Integer)
        s1 = ones(k) / k
        s2 = zeros(k)
        s3 = zeros(k)
        w = zeros(k)
        μ = collect(1.:k)
        σ2 = fill(10.0, k)
        new(s1, s2, s3, w, μ, σ2)
    end
end
function Base.show(io::IO, o::NormalMix)
    k = length(o.s1)
    print(io, "NormalMix (k = $k)")
    π = Ds.probs(o)
    c = Ds.components(o)
    for j in 1:k
        print(io, "  > $(π[j]) : $(c[j])\n")
    end
end
function value(o::NormalMix)
    vec = map((u,v) -> Ds.Normal{Float64}(u, sqrt(v)), o.μ, o.σ2)
    return Ds.MixtureModel(vec, o.s1)
end

Ds.componentwise_pdf(o::NormalMix, y) = Ds.componentwise_pdf(value(o), y)
Ds.ncomponents(o::NormalMix) = Ds.ncomponents(value(o))
Ds.component(o::NormalMix, j) = Ds.component(value(o), j)
Ds.components(o::NormalMix) = Ds.components(value(o))

function fit!(o::NormalMix, y::Real, γ::Float64)
    k = length(o.μ)
    for j in 1:k
        σinv = 1.0 / sqrt(o.σ2[j])
        o.w[j] = o.s1[j] * σinv * exp(-.5 * σinv * σinv * (y - o.μ[j]) ^ 2)
    end
    sum1 = sum(o.w)
    for j in 1:k
        o.w[j] /= sum1
        o.s1[j] = smooth(o.s1[j], o.w[j], γ)
        o.s2[j] = smooth(o.s2[j], o.w[j] * y, γ)
        o.s3[j] = smooth(o.s3[j], o.w[j] * y * y, γ)
    end
    sum2 = sum(o.s1)
    for j in 1:k
        o.μ[j] = o.s2[j] / o.s1[j]
        o.σ2[j] = (o.s3[j] - o.s2[j] ^ 2 / o.s1[j]) / o.s1[j]
        o.s1[j] /= sum2
        if o.σ2[j] <= ϵ
            o.σ2 = ones(k)
        end
    end
    o
end

# function fitbatch!{T<:Real}(o::NormalMix, y::AVec{T}, γ::Float64)
#     n = length(y)
#     k = length(o.μ)
#     s1 = copy(o.s1)
#     s2 = copy(o.s2)
#     s3 = copy(o.s3)
#
#     for yi in y
#         for j in 1:k
#             σinv = 1.0 / sqrt(o.σ2[j])
#             o.w[j] = s1[j] * σinv * exp(-.5 * σinv * σinv * (yi - o.μ[j]) ^ 2)
#         end
#         sum1 = sum(o.w)
#         for j in 1:k
#             o.w[j] /= sum1
#             if yi == y[1]
#                 o.s1[j] = smooth(o.s1[j], o.w[j] / n, γ)
#                 o.s2[j] = smooth(o.s2[j], o.w[j] * yi / n, γ)
#                 o.s3[j] = smooth(o.s3[j], o.w[j] * yi * yi / n, γ)
#             else
#                 o.s1[j] += γ * o.w[j] / n
#                 o.s2[j] += γ * o.w[j] * yi / n
#                 o.s3[j] += γ * o.w[j] * yi * yi / n
#             end
#         end
#     end
#     sum2 = sum(o.s1)
#     for j in 1:k
#         o.μ[j] = o.s2[j] / o.s1[j]
#         o.σ2[j] = (o.s3[j] - o.s2[j] ^ 2 / o.s1[j]) / o.s1[j]
#         o.s1[j] /= sum2
#         if o.σ2[j] <= ϵ
#             o.σ2 = ones(k)
#         end
#     end
#     o
# end


# # Quantiles via Newton's method.  Starting values based on Normal distribution.
# function Base.quantile(o::NormalMix, τ::Real; start = quantile(Ds.Normal(mean(o), std(o)), τ),
#                        maxit = 20, tol = .001)
#     0 < τ < 1 || throw(ArgumentError("τ must be in (0, 1)"))
#
#     θ = start
#     for i in 1:maxit
#         θ += (τ - Ds.cdf(o, θ)) / Ds.pdf(o, θ)
#         abs(Ds.cdf(o, θ) - τ) < tol && break
#     end
#     return θ
# end
# function Base.quantile{T<:Real}(o::NormalMix, τ::Vector{T};
#         start = start = quantile(Ds.Normal(mean(o), std(o)), τ), kw...
#     )
#     Float64[quantile(o, τ[j]; start = start[j], kw...) for j in 1:length(τ)]
# end
