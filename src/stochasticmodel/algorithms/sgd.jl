"Stochastic (Sub)Gradient Descent"
immutable SGD <: Algorithm   # step size is γ = η * nobs ^ -r
    η::Float64
    rate::LearningRate
    function SGD(;η::Real = 1.0, kw...)
        @assert η > 0
        @compat new(Float64(η), LearningRate(kw...))
    end
end
weight(alg::SGD) = alg.η * weight(alg.rate)
Base.show(io::IO, o::SGD) = print(io, "SGD with rate γ_t = $(o.η) / (1 + $(o.rate.λ) * t^$(o.rate.r))")

@inline function updateβ!(o::StochasticModel{SGD}, x::AVecF, y::Float64)
    g = ∇f(o.model, y, predict(o, x))
    # γ = alg(o).η / nobs(o) ^ alg(o).r
    γ = weight(o.algorithm)

    if o.intercept
        o.β0 -= γ * g
    end

    @inbounds for j in 1:length(x)
        o.β[j] -= γ * add∇j(g * x[j], pen(o), o.β, j)
    end
    nothing
end

# For adding penalties
@inline add∇j(x::Float64, ::NoPenalty, β::VecF, i::Int) = x
@inline add∇j(x::Float64, p::L2Penalty, β::VecF, i::Int) = x + p.λ * β[i]
@inline add∇j(x::Float64, p::L1Penalty, β::VecF, i::Int) = x + p.λ * sign(β[i])
@inline add∇j(x::Float64, p::ElasticNetPenalty, β::VecF, i::Int) = x + p.λ * (p.α * sign(β[i]) + (1 - p.α) * β[i])
@inline function add∇j(x::Float64, p::SCADPenalty, β::VecF, i::Int)
    if abs(β[i]) < p.λ
        x + sign(β[i]) * p.λ
    elseif abs(β[i]) < p.a * p.λ
        x + max(p.a * p.λ - abs(β[i]), 0.0) / (p.a - 1.0)
    else
        x
    end
end
