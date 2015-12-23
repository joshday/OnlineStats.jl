type NormalMix{W<:Weight} <: OnlineStat
    value::Ds.MixtureModel{Ds.Univariate, Ds.Continuous, Ds.Normal}
    s1::VecF
    s2::VecF
    s3::VecF
    weight::W
    n::Int
    nup::Int
end
function NormalMix(k::Integer, wgt::Weight = LearningRate())
    NormalMix(
        Ds.MixtureModel(Ds.Normal[Ds.Normal(j-1, 10) for j in 1:k]),
        zeros(k),
        zeros(k),
        zeros(k),
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
function Base.show(io::IO, o::NormalMix)
    printheader(io, "NormalMix (k = $(Ds.ncomponents(o)))")
    print_value_and_nobs(io, o)
end


function fit!(o::NormalMix, y::Real)
    γ = weight!(o, 1)
    w = Ds.componentwise_pdf(o, y)
    k = length(w)
    π = Ds.probs(o)
    for j in 1:k
        w *= π[j]
    end
    w /= sum(w)
    for j in 1:k
        o.s1[j] = smooth(o.s1[j], w[j], γ)
        o.s2[j] = smooth(o.s2[j], w[j] * y, γ)
        o.s3[j] = smooth(o.s3[j], w[j] * y * y, γ)
    end

    π = o.s1
    π ./= sum(π)
    μ = o.s2 ./ o.s1
    σ = (o.s3 - (o.s2 .* o.s2 ./ o.s1)) ./ o.s1
    if any(σ .<= 0.)
        σ = ones(k)
    end

    o.value = Ds.MixtureModel(map((u,v) -> Ds.Normal(u, v), vec(μ), vec(sqrt(σ))), vec(π))
end


y = rand(Ds.MixtureModel([Ds.Normal(0,1), Ds.Normal(5, 2), Ds.Normal(10, 10)], [.2, .4, .4]), 10000)
@time o = NormalMix(y, 3, LearningRate(.5))
display(o)
