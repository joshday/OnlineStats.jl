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
    if o.algorithm.n_updates == 0
        o.algorithm.d = zeros(length(x)) + o.algorithm.d0
    end
    o.algorithm.n_updates += 1
    ŷ = predict(o, x)
    γ = weight(o)
    g = ∇f(o.model, y, predict(o, x))
    w = 1 / nobs(o)

    if o.intercept
        d = mmdenom(o.model, 1.0, y, ŷ, makeα(o, 1.0, x))
        o.algorithm.d0 = smooth(o.algorithm.d0, d, w)
        o.β0 -= γ * g / o.algorithm.d0
    end

    for j in 1:length(x)
        d = mmdenom(o.model, x[j], y, ŷ, makeα(o, x[j], x))
        o.algorithm.d[j] = smooth(o.algorithm.d[j], d, w)
        o.β[j] -= γ * add∇j(o.penalty, g * x[j], o.β, j) / o.algorithm.d[j]
    end
end

function updatebatchβ!(o::StochasticModel{MMGrad}, x::AMatF, y::AVecF)
    if o.algorithm.n_updates == 0
        o.algorithm.d = zeros(size(x, 2)) + o.algorithm.d0
    end
    o.algorithm.n_updates += 1
    ŷ = predict(o, x)
    γ = weight(o) / length(y)  # divide by batch size to get average gradient

    for i in 1:length(y)
        g = ∇f(o.model, y[i], ŷ[i])
        w = 1 / (nobs(o) + i)
        if o.intercept
            d = mmdenom(o.model, 1.0, y[i], ŷ[i], makeα(o, 1.0, row(x, i)))
            o.algorithm.d0 = smooth(o.algorithm.d0, d, w)
            o.β0 -= γ * g / o.algorithm.d0
        end

        for j in 1:size(x, 2)
            d = mmdenom(o.model, x[i, j], y[i], ŷ[i], makeα(o, x[i, j], row(x, i)))
            o.algorithm.d[j] = smooth(o.algorithm.d[j], d, w)
            o.β[j] -= γ * add∇j(o.penalty, g * x[i, j], o.β, j) / o.algorithm.d[j]
        end
    end
end

# makeα(o, xj, x) = abs(xj) / (sumabs(x) + o.intercept)
makeα(o, xj, x) = abs2(xj) / (sumabs2(x) + o.intercept)


function mmdenom(::LogisticRegression, xj::Float64, y::Float64, ŷ::Float64, α::Float64)
    xj^2 / α * (ŷ * (1 - ŷ) + .0001)
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
