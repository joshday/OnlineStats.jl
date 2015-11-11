"""
### Stochastic MM Gradient

Uses noisy first derivative and averaged second derivative of separated majorizing function.
Think of this as second-order SGD, but updates have the same cost as simple SGD.
"""
type MMGrad <: Algorithm
    weighting::LearningRate
    η::Float64
    d0::Float64
    d::Vector{Float64}
    n_updates::Int

    function MMGrad(; ϵ::Real = .1, η::Real = 1.0, kw...)
        @assert ϵ > 0
        @assert η > 0
        new(LearningRate(;kw...), Float64(η), Float64(ϵ), zeros(1), 0)
    end
    function MMGrad(wgt::LearningRate; ϵ::Real = .01, η::Real = 1.0)
        @assert ϵ > 0
        @assert η > 0
        new(wgt, Float64(η), Float64(ϵ), zeros(1), 0)
    end
end



Base.show(io::IO, o::MMGrad) = println(io, "MMGrad with ", typeof(o.weighting))
weight(o::StochasticModel{MMGrad}) = o.algorithm.η * weight(o.algorithm.weighting, o.algorithm.n_updates, 1)

function updateβ!(o::StochasticModel{MMGrad}, x::AVecF, y::Float64)
    if nobs(o) == 1
        o.algorithm.d = zeros(length(x)) + o.algorithm.d0
    end
    o.algorithm.n_updates += 1
    ŷ = predict(o, x)
    γ = weight(o)
    g = ∇f(o.model, y, predict(o, x))
    w = 1 / o.algorithm.n_updates

    if o.intercept
        d = mmdenom(o.model, 1.0, y, ŷ, makeα(o, 1.0, x))
        o.algorithm.d0 = smooth(o.algorithm.d0, d, w)
        o.β0 -= γ * g / o.algorithm.d0
    end

    for j in 1:length(x)
        d = mmdenom(o.model, x[j], y, ŷ, makeα(o, x[j], x))
        o.algorithm.d[j] = smooth(o.algorithm.d[j], d, w)
        o.β[j] -= γ * g * x[j] / o.algorithm.d[j]
    end
end

function updatebatchβ!(o::StochasticModel{MMGrad}, x::AVecF, y::Float64)
    error("no batch update method when using algorithm MMGrad")
end

makeα(o, xj, x) = abs(xj) / (sumabs(x) + o.intercept)
# makeα(o, xj, x) = abs2(xj) / (sumabs2(x) + o.intercept)


function mmdenom(::LogisticRegression, xj::Float64, y::Float64, ŷ::Float64, α::Float64)
    xj^2 / α * ŷ * (1 - ŷ)
end

function mmdenom(::PoissonRegression, xj::Float64, y::Float64, ŷ::Float64, α::Float64)
    xj^2 * ŷ / α
end

function mmdenom(::L2Regression, xj::Float64, y::Float64, ŷ::Float64, α::Float64)
    xj^2 / α
end

function mmdenom(::QuantileRegression, xj::Float64, y::Float64, ŷ::Float64, α::Float64)
    xj^2 / (α * abs(y - ŷ))  # Uses Lange Majorization to get second order information
end


# TODO: L1Regression, SVMLike, HuberRegression
function mmdenom(m::ModelDefinition, γ::Float64, x::AVecF, y::Float64, ŷ::Float64)
    error("MMGrad is not implemented for model: ", typeof(m))
end





# TEST
if false
    # srand(10)
    n, p = 1_000_000, 10
    x = randn(n, p) * 4
    β = collect(linspace(-1, 1, p))
    # β = ones(p)

    y = x*β + randn(n)
    # y = Float64[rand(Bernoulli(1 / (1 + exp(-xb)))) for xb in x*β]
    # y = Float64[rand(Poisson(exp(xb))) for xb in x*β]
    β = vcat(0.0, β)

    @time o = StochasticModel(x, y, algorithm = MMGrad(r = .5), model = QuantileRegression())
    @time o2 = StochasticModel(x, y, algorithm = SGD(r = .5), model = QuantileRegression())
    @time o3 = StochasticModel(x, y, algorithm = ProxGrad(), model = QuantileRegression())
    @time o4 = StochasticModel(x, y, algorithm = RDA(), model = QuantileRegression())

    show(o)
    show(o2)
    show(o3)
    show(o4)

    println("mm:  ", maxabs(coef(o) - β))
    println("sgd: ", maxabs(coef(o2) - β))
    println("prox:", maxabs(coef(o3) - β))
    println("rda: ", maxabs(coef(o4) - β))
end
