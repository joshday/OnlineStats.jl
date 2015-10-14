"""
### Stochastic (Sub)Gradient Descent with sparsity.

`SGDSparse(;burnin = 1000, cutoff = .0001, kw...)`

Takes the same keywords as `SGD`, plus `burnin` and `cutoff`.

After `burnin` observations, if the absolute value of an estimate is less than
`cutoff`, it will be set to 0 and no longer updated.
"""
type SGDSparse <: Algorithm   # step size is γ = η * nobs ^ -r
    η::Float64
    rate::LearningRate
    set::IntSet
    burnin::Int
    cutoff::Float64
    function SGDSparse(;η::Real = 1.0, burnin = 1000, cutoff = .0001, kw...)
        @assert η > 0
        @compat new(Float64(η), LearningRate(;kw...), IntSet(1:2), burnin, cutoff)
    end
end
weight(alg::SGDSparse) = alg.η * weight(alg.rate)
Base.show(io::IO, o::SGDSparse) = print(io, "SGDSparse with rate γ_t = $(o.η) / (1 + $(o.rate.λ) * t ^ $(o.rate.r))")

@inline function updateβ!(o::StochasticModel{SGDSparse}, x::AVecF, y::Float64)
    if nobs(o) == 1
        alg(o).set = IntSet(1:length(x))
    end
    g = ∇f(o.model, y, predict(o, x))
    # γ = alg(o).η / nobs(o) ^ alg(o).r
    γ = weight(o.algorithm)

    if o.intercept
        o.β0 -= γ * g
    end

    @inbounds for j in alg(o).set
        o.β[j] -= γ * add∇j(g * x[j], pen(o), o.β, j)
    end

    if nobs(o) > alg(o).burnin
        for j in alg(o).set
            if abs(o.β[j]) < alg(o).cutoff
                o.β[j] = 0.0
                delete!(alg(o).set, j)
            end
        end
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
