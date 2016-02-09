"""
`NormalMix(k, wgt; start)`

Normal Mixture of `k` components via an online EM algorithm.  `start` is a keyword
argument specifying the initial parameters.

If the algorithm diverges, try using a different `start`.

Example:

`NormalMix(k, wgt; start = MixtureModel(Normal, [(0, 1), (3, 1)]))`
"""
type NormalMix{W<:Weight} <: DistributionStat{ScalarInput}
    value::Ds.MixtureModel{Ds.Univariate, Ds.Continuous, Ds.Normal}
    s1::VecF
    s2::VecF
    s3::VecF
    w::VecF
    μ::VecF
    σ2::VecF
    weight::W
end
function NormalMix(k::Integer, wgt::Weight = LearningRate();
        start = Ds.MixtureModel(Ds.Normal[Ds.Normal(j-1, 10) for j in 1:k])
    )
    NormalMix(
        start,
        ones(k) / k, zeros(k), zeros(k),  # s1, s2, s3
        zeros(k), collect(1.:k), fill(10.0, k),  # w, μ, σ2
        wgt
    )
end
function NormalMix(y::AVec, k::Integer, wgt::Weight = LearningRate(); kw...)
    o = NormalMix(k, wgt; kw...)
    fit!(o, y)
    o
end
NormalMix(k::Integer, y::AVec, wgt::Weight = LearningRate(); kw...) = NormalMix(y, k, wgt; kw...)
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
    try
        o.value = Ds.MixtureModel(map((u,v) -> Ds.Normal(u, sqrt(v)), o.μ, o.σ2), o.s1)
    catch
        println(sqrt(o.σ2))
        println(sqrt(o.μ))
        println(sqrt(o.s1))
        error("Algorithm is fucked, nobs = $(nobs(o))")
    end
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
    end
    sum2 = sum(o.s1)
    for j in 1:k
        o.μ[j] = o.s2[j] / o.s1[j]
        o.σ2[j] = (o.s3[j] - o.s2[j] ^ 2 / o.s1[j]) / o.s1[j]
        o.s1[j] /= sum2
        if o.σ2[j] <= _ϵ
            o.σ2 = ones(k)
        end
    end
    o
end
function fitbatch!{T<:Real}(o::NormalMix, y::AVec{T})
    n = length(y)
    γ = weight!(o, n)
    k = length(o.μ)
    s1 = copy(o.s1)
    s2 = copy(o.s2)
    s3 = copy(o.s3)

    for yi in y
        for j in 1:k
            σinv = 1.0 / sqrt(o.σ2[j])
            o.w[j] = s1[j] * σinv * exp(-.5 * σinv * σinv * (yi - o.μ[j]) ^ 2)
        end
        sum1 = sum(o.w)
        for j in 1:k
            o.w[j] /= sum1
            if yi == y[1]
                o.s1[j] = smooth(o.s1[j], o.w[j] / n, γ)
                o.s2[j] = smooth(o.s2[j], o.w[j] * yi / n, γ)
                o.s3[j] = smooth(o.s3[j], o.w[j] * yi * yi / n, γ)
            else
                o.s1[j] += γ * o.w[j] / n
                o.s2[j] += γ * o.w[j] * yi / n
                o.s3[j] += γ * o.w[j] * yi * yi / n
            end
        end
    end
    sum2 = sum(o.s1)
    for j in 1:k
        o.μ[j] = o.s2[j] / o.s1[j]
        o.σ2[j] = (o.s3[j] - o.s2[j] ^ 2 / o.s1[j]) / o.s1[j]
        o.s1[j] /= sum2
        if o.σ2[j] <= _ϵ
            o.σ2 = ones(k)
        end
    end
    o
end


# Quantiles.  Starting values based on Normal distribution.
function Base.quantile(o::NormalMix, τ::Real;
        start = quantile(Ds.Normal(mean(o), std(o)), τ), maxit = 20, tol = .001
    )
    @assert 0 < τ < 1
    θ = start
    for i in 1:maxit
        θ += (τ - Ds.cdf(o, θ)) / Ds.pdf(o, θ)
        abs(Ds.cdf(o, θ) - τ) < tol && break
    end
    return θ
end
function Base.quantile{T<:Real}(o::NormalMix, τ::Vector{T};
        start = start = quantile(Ds.Normal(mean(o), std(o)), τ), kw...
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
#     nups::Int
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
