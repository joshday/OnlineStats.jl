# The best approach is to use start = em()
#-------------------------------------------------------# Type and Constructors
type NormalMix <: DistributionStat
    d::MixtureModel{Univariate, Continuous, Normal}    # MixtureModel
    s1::VecF             # sum of weights
    s2::VecF             # sum of (weights .* y)
    s3::VecF             # sum of (weights .* y .* y)
    n::Int64                        # number of observations
    weighting::StochasticWeighting
end


function NormalMix(p::Int, y::VecF, wgt::StochasticWeighting = StochasticWeighting(),
                   start = emstart(p, y, verbose = true))
    o = NormalMix(p, wgt, start)
    updatebatch!(o, y)
    o
end
function NormalMix(p::Int, y::Float64, wgt::StochasticWeighting = StochasticWeighting(),
                   start = MixtureModel(map((u,v) -> Normal(u, v), zeros(p), ones(p))))
    o = NormalMix(p, wgt, start)
    update!(o, y)
    o
end
function NormalMix(p::Int, wgt::StochasticWeighting = StochasticWeighting(),
                   start = MixtureModel(map((u,v) -> Normal(u, v), zeros(p), ones(p))))
    NormalMix(start, zeros(p), zeros(p), zeros(p), 0, wgt)
end


#---------------------------------------------------------------------# update!
function updatebatch!(o::NormalMix, y::Vector{Float64})
    n = length(y)
    nc = length(components(o))
    π = probs(o)
    w::MatF = zeros(n, nc)
    for i = 1:n, j = 1:nc
        w[i, j] = π[j] * pdf(o.d.components[j], y[i])
    end
    w ./= sum(w, 2)
    s1 = vec(sum(w, 1))
    s2 = vec(sum(w .* y, 1))
    s3 = vec(sum(w .* y .* y, 1))

    γ = weight(o)
    smooth!(o.s1, s1, γ)
    smooth!(o.s2, s2, γ)
    smooth!(o.s3, s3, γ)

    π = o.s1
    π ./= sum(π)
    μ = o.s2 ./ o.s1
    σ = (o.s3 - (o.s2 .* o.s2 ./ o.s1)) ./ o.s1

    o.d = MixtureModel(map((u,v) -> Normal(u, v), vec(μ), vec(sqrt(σ))), vec(π))
    o.n += n
end


#------------------------------------------------------------------------# state
statenames(o::NormalMix) = [:μ, :σ, :π, :nobs]
state(o::NormalMix) = Any[means(o), stds(o), probs(o), nobs(o)]

means(o::NormalMix) = means(o.d)
stds(o::NormalMix) = stds(o.d)

components(o::NormalMix) = components(o.d)
probs(o::NormalMix) = probs(o.d)


