"Stochastic (Sub)Gradient Descent"
immutable SGD <: Algorithm   # step size is γ = η * nobs ^ -r
    η::Float64
    weighting::LearningRate
    function SGD(;η::Real = 1.0, kw...)
        @assert η > 0
        new(Float64(η), LearningRate(;kw...))
    end
end

weight(alg::SGD) = alg.η * weight(alg.weighting)

Base.show(io::IO, o::SGD) = print(io, "SGD with rate γ_t = $(o.η) / (1 + $(o.weighting.λ) * t) ^ $(o.weighting.r)")


function updateβ!(o::StochasticModel{SGD}, x::AVecF, y::Float64)
    g = ∇f(o.model, y, predict(o, x))
    γ = weight(o.algorithm)

    if o.intercept
        o.β0 -= γ * g
    end

    @inbounds for j in 1:length(x)
        o.β[j] -= γ * add∇j(pen(o), g * x[j], o.β, j)
    end
end

function updatebatchβ!(o::StochasticModel{SGD}, x::AMatF, y::AVecF)
    n = length(y)
    γ = weight(o.algorithm) / n
    for i in 1:n
        xi = rowvec_view(x, i)
        g = ∇f(o.model, y[i], predict(o, xi))

        if o.intercept
            o.β0 -= γ * g
        end

        @inbounds for j in 1:size(x, 2)
            o.β[j] -= γ * add∇j(pen(o), g * xi[j], o.β, j)
        end
    end
end

# For adding penalties
@inline add∇j(::NoPenalty, g::Float64, β::VecF, i::Int) = g
@inline add∇j(p::L2Penalty, g::Float64, β::VecF, i::Int) = g + p.λ * β[i]
@inline add∇j(p::L1Penalty, g::Float64, β::VecF, i::Int) = g + p.λ * sign(β[i])
@inline add∇j(p::ElasticNetPenalty, g::Float64, β::VecF, i::Int) = g + p.λ * (p.α * sign(β[i]) + (1 - p.α) * β[i])
@inline function add∇j(p::SCADPenalty, g::Float64, β::VecF, i::Int)
    if abs(β[i]) < p.λ
        g + sign(β[i]) * p.λ
    elseif abs(β[i]) < p.a * p.λ
        g + max(p.a * p.λ - abs(β[i]), 0.0) / (p.a - 1.0)
    else
        g
    end
end
