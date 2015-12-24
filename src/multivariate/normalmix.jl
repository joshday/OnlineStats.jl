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
function NormalMix(k::Integer, wgt::Weight = LearningRate())
    NormalMix(
        Ds.MixtureModel(Ds.Normal[Ds.Normal(j-1, 10) for j in 1:k]),
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
        # o.w[j] = Ds.pdf(Ds.component(o,j), y) * o.s1[j]
        σinv = 1.0 / sqrt(o.σ2[j])
        o.w[j] = o.s1[j] * σinv * exp(-.5 * σinv * σinv * (y - o.μ[j]) ^ 2)
    end
    o.w /= sum(o.w)
    for j in 1:k
        o.s1[j] = smooth(o.s1[j], o.w[j], γ)
        o.s2[j] = smooth(o.s2[j], o.w[j] * y, γ)
        o.s3[j] = smooth(o.s3[j], o.w[j] * y * y, γ)

        o.μ[j] = o.s2[j] / o.s1[j]
        o.σ2[j] = (o.s3[j] - o.s2[j] ^ 2 / o.s1[j]) / o.s1[j]
    end
    ss1 = sum(o.s1)
    for j in 1:k
        o.s1[j] /= ss1
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
    o.s /= sum(o.w)
    for j in 1:k
        o.s1[j] = smooth(o.s1[j], o.w[j], γ)
        o.s2[j] = smooth(o.s2[j], o.w[j] * y, γ)
        o.s3[j] = smooth(o.s3[j], o.w[j] * y * y, γ)

        o.μ[j] = o.s2[j] / o.s1[j]
        o.σ2[j] = (o.s3[j] - o.s2[j] ^ 2 / o.s1[j]) / o.s1[j]
    end
    ss1 = sum(o.s1)
    for j in 1:k
        o.s1[j] /= ss1
        if o.σ2[j] <= 0
            o.σ2 = ones(k)
        end
    end
end



# testing
d = Ds.MixtureModel([Ds.Normal(0,1), Ds.Normal(5,2), Ds.Normal(10,10)], [.4, .2, .4])
y = rand(d, 1_000_000)
o = NormalMix(3, LearningRate(.6))
fit!(o, y, 10)

Profile.clear()
@profile o = NormalMix(y, 3, LearningRate(.6))
display(o)
