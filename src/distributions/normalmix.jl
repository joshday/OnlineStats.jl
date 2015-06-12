#-------------------------------------------------------# Type and Constructors
type NormalMix <: DistributionStat
    d::MixtureModel{Univariate, Continuous, Normal}    # MixtureModel
    s1::VecF             # sum of weights
    s2::VecF             # sum of (weights .* y)
    s3::VecF             # sum of (weights .* y .* y)
    n::Int64                        # number of observations
    weighting::StochasticWeighting
end


function NormalMix(p::Int, y::VecF, wgt::StochasticWeighting = StochasticWeighting(); start = emstart(p, y, verbose = false))
    o = NormalMix(p, wgt, start = start)
    updatebatch!(o, y)
    o
end
function NormalMix(p::Int, y::Float64, wgt::StochasticWeighting = StochasticWeighting();
                   start = MixtureModel(map((u,v) -> Normal(u, v), zeros(p), ones(p))))
    o = NormalMix(p, wgt, start = start)
    update!(o, y)
    o
end
function NormalMix(p::Int, wgt::StochasticWeighting = StochasticWeighting();
                   start = MixtureModel(map((u,v) -> Normal(u, v), zeros(p), ones(p))))
    NormalMix(start, zeros(p), zeros(p), zeros(p), 0, wgt)
end


#------------------------------------------------------------------------# state
means(o::NormalMix) = means(o.d)
stds(o::NormalMix) = stds(o.d)

components(o::NormalMix) = components(o.d)
probs(o::NormalMix) = probs(o.d)


#---------------------------------------------------------------------# update!
function updatebatch!(o::NormalMix, y::Vector{Float64})
    n = length(y)
    nc = length(components(o))
    π = probs(o)
    γ = weight(o)

    w::MatF = zeros(n, nc)
    for j = 1:nc, i = 1:n
        @inbounds w[i, j] = π[j] * pdf(components(o)[j], y[i])
    end
    w ./= sum(w, 2)
    s1 = vec(sum(w, 1))
    s2 = vec(sum(w .* y, 1))
    s3 = vec(sum(w .* y .* y, 1))
    smooth!(o.s1, s1, γ)
    smooth!(o.s2, s2, γ)
    smooth!(o.s3, s3, γ)

    π = o.s1
    π ./= sum(π)
    μ = o.s2 ./ o.s1
    σ = (o.s3 - (o.s2 .* o.s2 ./ o.s1)) ./ o.s1
    if any(σ .== 0.)
        σ = ones(nc)
    end

    o.d = MixtureModel(map((u,v) -> Normal(u, v), vec(μ), vec(sqrt(σ))), vec(π))
    o.n += n
    return
end


function update!(o::NormalMix, y::Float64)
    γ = weight(o)
    p = length(o.s1)

    w::VecF = zeros(p)
    for j in 1:p
        w[j] = pdf(o.d.components[j], y)
    end
    w /= sum(w)
    for j in 1:p
        o.s1[j] = smooth(o.s1[j], w[j], γ)
        o.s2[j] = smooth(o.s2[j], w[j] * y, γ)
        o.s3[j] = smooth(o.s3[j], w[j] * y * y, γ)
    end

    π = o.s1
    π ./= sum(π)
    μ = o.s2 ./ o.s1
    σ = (o.s3 - (o.s2 .* o.s2 ./ o.s1)) ./ o.s1
    if any(σ .== 0.)
        σ = ones(p)
    end

    o.d = MixtureModel(map((u,v) -> Normal(u, v), vec(μ), vec(sqrt(σ))), vec(π))
    o.n += 1
    return
end





