"""
    NormalMix(k)
    NormalMix(k, init_data)
"""
mutable struct NormalMix <: DistributionStat{0}
    s1::VecF
    s2::VecF
    s3::VecF
    w::VecF
    μ::VecF
    σ2::VecF
    nobs::Int
    function NormalMix(k::Integer, μ::VecF, σ2::VecF)
        s1 = ones(k) / k
        s2 = zeros(k)
        s3 = zeros(k)
        w = zeros(k)
        new(s1, s2, s3, w, μ, σ2, 0)
    end
    NormalMix(k::Integer) = NormalMix(k, collect(linspace(-10, 10, k)), fill(10.0, k))
    function NormalMix(k::Integer, train::VecF)
        μ = quantile(train, collect(linspace(0, 1, k + 2))[2:(end - 1)])
        σ2 = fill(var(train), k)
        NormalMix(k, μ, σ2)
    end
end
function Base.show(io::IO, o::NormalMix)
    k = length(o.s1)
    print(io, "NormalMix (k = $k)\n")
    π = Ds.probs(o)
    c = Ds.components(o)
    for j in 1:k
        print(io, "  > $(π[j]) : $(c[j])\n")
    end
end
function value(o::NormalMix)
    for j in eachindex(o.μ)
        o.μ[j] = o.s2[j] / o.s1[j]
        o.σ2[j] = (o.s3[j] - o.s2[j] ^ 2 / o.s1[j]) / o.s1[j]
    end
    scale!(o.s1, inv(sum(o.s1)))
    if o.nobs > 1
        vec = map((u,v) -> Ds.Normal{Float64}(u, sqrt(v)), o.μ, o.σ2)
        return Ds.MixtureModel(vec, o.s1)
    else
        return Ds.MixtureModel([Ds.Normal() for i in 1:length(o.μ)])
    end
end

for f in [:component_type, :ncomponents, :components]
    @eval Ds.$f(o::NormalMix) = Ds.$f(value(o))
end
Ds.component(o::NormalMix, j) = Ds.component(value(o), j)


function get_w!(o::NormalMix, y)
    for j in eachindex(o.μ)
        o.w[j] = o.s1[j] * mean(Ds.pdf(Ds.Normal(o.μ[j], sqrt(o.σ2[j])), y))
    end
    scale!(o.w, inv(sum(o.w)))
end

# Works also for fitbatch! default definition
function fit!(o::NormalMix, y, γ::Float64)
    get_w!(o, y)
    o.nobs += 1
    for j in eachindex(o.s1)
        o.s1[j] = smooth(o.s1[j], o.w[j], γ)
        o.s2[j] = smooth(o.s2[j], o.w[j] * mean(y), γ)
        o.s3[j] = smooth(o.s3[j], o.w[j] * mean(y .* y), γ)
    end
    o
end
fitbatch!(o::NormalMix, y::AVec, γ::Float64) = fit!(o, y, γ)


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
