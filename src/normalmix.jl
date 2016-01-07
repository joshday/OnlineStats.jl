type NormalMix{W<:Weight} <: OnlineStat
    value::Ds.MixtureModel{Ds.Univariate, Ds.Continuous, Ds.Normal}
    s1::VecF
    s2::VecF
    s3::VecF
    w::VecF
    μ::VecF
    σ2::VecF
    weight::W
    n::Int
    nup::Int
end
function NormalMix(k::Integer, wgt::Weight = LearningRate();
        start = Ds.MixtureModel(Ds.Normal[Ds.Normal(j-1, 10) for j in 1:k])
    )
    NormalMix(
        start,
        ones(k) / k, zeros(k), zeros(k),  # s1, s2, s3
        zeros(k), collect(1.:k), fill(10.0, k),  # w, μ, σ2
        wgt, 0, 0
    )
end
function NormalMix(y::AVec, k::Integer, wgt::Weight = LearningRate())
    o = NormalMix(k, wgt)
    fit!(o, y)
    o
end
Ds.componentwise_pdf(o::NormalMix, y) = Ds.componentwise_pdf(value(o), y)
Ds.ncomponents(o::NormalMix) = Ds.ncomponents(value(o))
Ds.component(o::NormalMix, j) = Ds.component(value(o), j)
Ds.probs(o::NormalMix) = Ds.probs(value(o))
Ds.pdf(o::NormalMix, y) = Ds.pdf(value(o), y)
Ds.cdf(o::NormalMix, y) = Ds.cdf(value(o), y)
Base.mean(o::NormalMix) = mean(value(o))
Base.var(o::NormalMix) = var(value(o))
Base.std(o::NormalMix) = std(value(o))
function Base.show(io::IO, o::NormalMix)
    printheader(io, "NormalMix (k = $(Ds.ncomponents(o)))")
    print_value_and_nobs(io, o)
end
function value(o::NormalMix)
    o.value = Ds.MixtureModel(map((u,v) -> Ds.Normal(u, sqrt(v)), o.μ, o.σ2), o.s1)
end
function fit!(o::NormalMix, y::Real)
    γ = weight!(o, 1)
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

        o.μ[j] = o.s2[j] / o.s1[j]
        o.σ2[j] = (o.s3[j] - o.s2[j] ^ 2 / o.s1[j]) / o.s1[j]
    end
    sum2 = sum(o.s1)
    for j in 1:k
        o.s1[j] /= sum2
        if o.σ2[j] <= 0
            o.σ2 = ones(k)
        end
    end
end
function fitbatch!{T<:Real}(o::NormalMix, y::Vector{T})
    n2 = length(y)
    γ = weight!(o, n2)
    k = length(o.μ)
    for j in 1:k
        o.w[j] = 0.0
        for i in 1:n2
            σinv = 1.0 / sqrt(o.σ2[j])
            o.w[j] += σinv * exp(-.5 * σinv * σinv * (y[i] - o.μ[j]) ^ 2)
        end
        o.w[j] *= o.s1[j]
    end
    sum1 = sum(o.w)
    for j in 1:k
        o.w[j] /= sum1
        o.s1[j] = smooth(o.s1[j], o.w[j], γ)
        o.s2[j] = smooth(o.s2[j], o.w[j] * y, γ)
        o.s3[j] = smooth(o.s3[j], o.w[j] * y * y, γ)

        o.μ[j] = o.s2[j] / o.s1[j]
        o.σ2[j] = (o.s3[j] - o.s2[j] ^ 2 / o.s1[j]) / o.s1[j]
    end
    sum2 = sum(o.s1)
    for j in 1:k
        o.s1[j] /= sum2
        if o.σ2[j] <= 0
            o.σ2 = ones(k)
        end
    end
end


function quantilestart(o::NormalMix, τ::Real)
    # starting values based on Normal Distribution
    @assert 0 < τ < 1
    quantile(Ds.Normal(mean(o), std(o)), τ)
end
function Base.quantile(o::NormalMix, τ::Real; start = quantilestart(o, τ), maxit = 20, tol = .001)
    @assert 0 < τ < 1
    θ = start
    for i in 1:maxit
        θ += (τ - Ds.cdf(o, θ)) / Ds.pdf(o, θ)
        abs(Ds.cdf(o, θ) - τ) < tol && break
    end
    return θ
end
function Base.quantile{T<:Real}(o::NormalMix, τ::Vector{T};
        start = [quantilestart(o, τi) for τi in τ], kw...
    )
    Float64[quantile(o, τ[j]; start = start[j], kw...) for j in 1:length(τ)]
end


# #-----------------------------------------------------------------# Multivariate
# type MvNormalMix{W<:Weight} <: OnlineStat
#     value::Ds.MixtureModel{Ds.Multivariate, Ds.Continuous, Ds.MvNormal}
#     s1::VecF
#     s2::MatF
#     s3::Array{Float64, 3}
#     w::VecF
#     μ::MatF
#     V::Array{Float64, 3}
#     weight::W
#     n::Int
#     nup::Int
# end
# function MvNormalMix(p::Integer, k::Integer, wgt::Weight = LearningRate();
#         start = Ds.MixtureModel(Ds.MvNormal[Ds.MvNormal(ones(p) + j, 10 * eye(p)) for j in 1:k])
#     )
#     V = zeros(p, p, k)
#     # for j in 1:k
#     #     V[:, :, j] = cov(Ds.component(start, j))
#     # end
#
#     MvNormalMix(start,
#         ones(k) / k, zeros(p, k), zeros(p, p, k),  # s1, s2, s3
#         zeros(k), zeros(p, k), V,            # w, μ, V
#         wgt, 0, 0
#     )
# end
# function MvNormalMix{T<:Real}(y::AMat{T}, k::Integer, wgt::Weight = LearningRate(); kw...)
#     o = MvNormalMix(size(y, 2), k, wgt; kw...)
#     fit!(o, y)
#     o
# end
#
# function fit!{T<:Real}(o::MvNormalMix, y::AVec{T})
#     k = length(o.w)
#     γ = weight!(o, 1)
#     for j in 1:k
#         o.w[j] = o.s1[j] * Ds.pdf(Ds.component(o.value, j), y)
#     end
#     sum1 = sum(o.w)
#     for j in 1:k
#         o.w[j] /= sum1
#         o.s1[j] = smooth(o.s1[j], o.w[j], γ)
#         smooth!(o.s2[:, j], o.w[j] * y, γ)
#         smooth!(o.s3[:, :, j], o.w[j] * y * y', γ)
#
#         o.μ[:, j] = o.s2[j] / o.s1[j]
#         o.V[:, :, j] = (o.s3[:, :, j] - o.s2[j] * o.s2[j]' / o.s1[j]) / o.s1[j]
#     end
#
#     sum2 = sum(o.s1)
#     for j in 1:k
#         o.s1[j] /= sum2
#     end
#
#     o.value = Ds.MixtureModel(
#         Ds.MvNormal[
#             Ds.MvNormal(o.μ[:,j], o.V[:,:,j] + .001 * eye(length(o.μ[:,j]))) for j in 1:k
#         ],
#         o.s1 / sum(o.s1)
#     )
# end
#
