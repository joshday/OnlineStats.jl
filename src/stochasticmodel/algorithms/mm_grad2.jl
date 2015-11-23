"""
### MMGrad 2

Uses weighted average of first and second derivatives
"""
type MMGrad2 <: Algorithm
    weighting::LearningRate
    d::Vector{Float64}
    d2::Vector{Float64}
    n_updates::Int

    function MMGrad2(; ϵ::Real = .01, kw...)
        @assert ϵ > 0
        new(LearningRate(;kw...), zeros(1), fill(ϵ, 1), 0)
    end
    function MMGrad2(wgt::LearningRate; ϵ::Real = .01)
        @assert ϵ > 0
        new(wgt, zeros(1), fill(ϵ, 1), 0)
    end
end



Base.show(io::IO, o::MMGrad2) = println(io, "MMGrad2 with ", typeof(o.weighting))
weight(o::StochasticModel{MMGrad2}) = weight(o.algorithm.weighting, o.algorithm.n_updates, 1)

function updateβ!(o::StochasticModel{MMGrad2}, x::AVecF, y::Float64)
    if o.algorithm.n_updates == 0
        o.algorithm.d = zeros(length(x) + o.intercept)
        o.algorithm.d2 = fill(o.algorithm.d2[1], length(x) + o.intercept)
    end
    o.algorithm.n_updates += 1
    ŷ = predict(o, x)
    γ = weight(o)
    g = ∇f(o.model, y, predict(o, x))

    if o.intercept
        denom = mmdenom(o.model, 1.0, y, ŷ, makeα(o, 1.0, x))
        o.algorithm.d[1] = smooth(o.algorithm.d[1], g, γ)
        o.algorithm.d2[1] = smooth(o.algorithm.d2[1], denom, γ)
        o.β0 -= γ * o.algorithm.d[1] / o.algorithm.d2[1]
    end

    for j in 1:length(x)
        j₁ = j + o.intercept
        xj = x[j]
        denom = mmdenom(o.model, xj, y, ŷ, makeα(o, xj, x))
        o.algorithm.d[j₁] = smooth(o.algorithm.d[j₁], add∇j(o.penalty, g * xj, o.β, j), γ)
        o.algorithm.d2[j₁] = smooth(o.algorithm.d2[j₁], denom, γ)
        o.β[j] -= γ * o.algorithm.d[j₁] / o.algorithm.d2[j₁]
    end
end

# function updatebatchβ!(o::StochasticModel{MMGrad2}, x::AMatF, y::AVecF)
#     if o.algorithm.n_updates == 0
#         o.algorithm.d = zeros(size(x, 2)) + o.algorithm.d0
#     end
#     o.algorithm.n_updates += 1
#     ŷ = predict(o, x)
#     γ = weight(o) / length(y)  # divide by batch size to get average gradient
#
#     for i in 1:length(y)
#         g = ∇f(o.model, y[i], ŷ[i])
#         w = 1 / (nobs(o) + i)
#         if o.intercept
#             d = mmdenom(o.model, 1.0, y[i], ŷ[i], makeα(o, 1.0, row(x, i)))
#             o.algorithm.d0 = smooth(o.algorithm.d0, d, w)
#             o.β0 -= γ * g / o.algorithm.d0
#         end
#
#         for j in 1:size(x, 2)
#             d = mmdenom(o.model, x[i, j], y[i], ŷ[i], makeα(o, x[i, j], row(x, i)))
#             o.algorithm.d[j] = smooth(o.algorithm.d[j], d, w)
#             o.β[j] -= γ * add∇j(o.penalty, g * x[i, j], o.β, j) / o.algorithm.d[j]
#         end
#     end
# end
