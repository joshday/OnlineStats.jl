"""
### Stochastic MM Gradient

Uses average derivative/second derivative for updates after using separating majorization.
"""
type MMGrad2{W<:Weighting} <: Algorithm
    weighting::W
    η::Float64
    d0::Float64
    d::Vector{Float64}
end

function MMGrad2(wgt::Weighting = LearningRate(), ϵ = .01; η::Float64 = 1.0)
    MMGrad2(wgt, η, ϵ, zeros(1))
end

Base.show(io::IO, o::MMGrad2) = println(io, "MMGrad2 with ", typeof(o.weighting))

# weight(alg::MMGrad2) = weight(alg.weighting, )

function updateβ!{W<:Weighting}(o::StochasticModel{MMGrad2{W}}, x::AVecF, y::Float64)
    if nobs(o) == 1
        o.algorithm.d = zeros(length(x)) + o.algorithm.d0
    end
    ŷ = predict(o, x)
    γ = o.algorithm.η * weight(o.algorithm.weighting, nobs(o), 1)
    g = ∇f(o.model, y, predict(o, x))
    d = mmdenom(o.model, x, y, ŷ)

    if o.intercept
        o.algorithm.d0 = smooth(o.algorithm.d0, d, 1/nobs(o))
        o.β0 -= γ * g / d
    end

    for j in 1:length(x)
        o.algorithm.d[j] = smooth(o.algorithm.d[j], d, 1/nobs(o))
        o.β[j] -= γ * g * x[j] / d
    end
end



function mmdenom(::LogisticRegression, x::AVecF, y::Float64, ŷ::Float64, j::Int = 1)
    sumabs2(x) * ŷ * (1 - ŷ) + .01
end

function mmdenom(::PoissonRegression, x::AVecF, y::Float64, ŷ::Float64, j::Int = 1)
    sumabs2(x) * ŷ
end

function mmdenom(::L2Regression, x::AVecF, y::Float64, ŷ::Float64, j::Int = 1)
    sumabs2(x)
end
#
# function ∇f_mm(m::QuantileRegression, x::AVecF, y::Float64, ŷ::Float64)
#     # same as SGD
#     y < ŷ ? 1.0 - m.τ: -m.τ
# end

# function ∇f_mm(m::L1Regression, x::AVecF, y::Float64, ŷ::Float64)
#     - ((y - ŷ) + 0.5 * abs(y - ŷ)) / sumabs2(x)
# end


# # TODO: SVMLike and HuberRegression
# function ∇f_mm(m::ModelDefinition, γ::Float64, x::AVecF, y::Float64, ŷ::Float64)
#     error("This algorithm is not implemented for model: ", typeof(m))
# end





# TEST
if false
    # srand(10)
    n, p = 1_000_000, 10
    x = randn(n, p)
    β = collect(linspace(0, 1, p))
    # β = collect(1.:p)

    # y = x*β + randn(n)
    y = Float64[rand(Bernoulli(1 / (1 + exp(-xb)))) for xb in x*β]
    # y = Float64[rand(Poisson(exp(xb))) for xb in x*β]
    β = vcat(0.0, β)

    o = StochasticModel(p, algorithm = MMGrad2(LearningRate(r=.6)), model = LogisticRegression())
    @time update!(o, x, y)
    show(o)
    o2 = StochasticModel(p, algorithm = SGD(), model = LogisticRegression())
    @time update!(o2, x, y)
    show(o2)
    println("mm:  ", maxabs(coef(o) - β))
    println("sgd: ", maxabs(coef(o2) - β))

    # # l1reg
    # o = StochasticModel(p, algorithm = MMGrad2(), model = L2Regression())
    # @time update!(o, x, y)
    # show(o)
    # o = StochasticModel(p, algorithm = SGD(r = .5), model = L2Regression())
    # @time update!(o, x, y)
    # show(o)

    # o = StochasticModel(p, algorithm = MMGrad2(r = .6), model = LogisticRegression(), penalty = NoPenalty())
    # @time update!(o, x, y, 5)
    # show(o)
    #
    # o = StochasticModel(p, algorithm = SGD(r = .6), model = LogisticRegression(), penalty = NoPenalty())
    # @time update!(o, x, y, 5)
    # show(o)
    #
    # o = StochasticModel(p, algorithm = ProxGrad(), model = LogisticRegression(), penalty = NoPenalty())
    # @time update!(o, x, y, 5)
    # show(o)
    #
    # o = StochasticModel(p, algorithm = RDA(), model = LogisticRegression(), penalty = NoPenalty())
    # @time update!(o, x, y, 5)
    # show(o)
end
