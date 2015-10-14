"Stochastic (Sub)Gradient Descent"
immutable SGD <: Algorithm   # step size is γ = η * nobs ^ -r
    η::Float64
    r::Float64
    function SGD(;η::Real = 1.0, r::Real = .5)
        @assert η > 0
        @assert 0 < r <= 1
        @compat new(Float64(η), Float64(r))
    end
end

Base.show(io::IO, o::SGD) = print(io, "SGD(η = $(o.η), r = $(o.r))")

@inline function updateβ!(o::StochasticModel{SGD}, x::AVecF, y::Float64)
    g = ∇f(o.model, y, predict(o, x))
    γ = alg(o).η / nobs(o) ^ alg(o).r

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
