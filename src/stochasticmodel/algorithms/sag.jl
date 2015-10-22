# http://arxiv.org/pdf/1309.2388v1.pdf
"Stochastic Average Gradient"
type SAG <: Algorithm   # step size is γ = η * nobs ^ -r
    η::Float64
    rate::LearningRate
    G0::Float64
    G::VecF    # historical gradient vector
    function SAG(;η::Real = 1.0, kw...)
        @assert η > 0
        new(Float64(η), LearningRate(;kw...), 0.0, zeros(2))
    end
end

weight(alg::SAG) = alg.η * weight(alg.rate)
Base.show(io::IO, o::SAG) = print(io, "SAG with rate γ_t = $(o.η) / (1 + $(o.rate.λ) * t ^ $(o.rate.r))")

@inline function updateβ!(o::StochasticModel{SAG}, x::AVecF, y::Float64)
    if nobs(o) == 1
        alg(o).G = zeros(length(x))
    end

    g = ∇f(o.model, y, predict(o, x))
    γ = weight(alg(o))

    if o.intercept
        alg(o).G0 = g
        o.β0 -= γ * g
    end

    j = rand(1:length(x))
    alg(o).G[j] = add∇j(g * x[j], pen(o), o.β, j)

    @inbounds for j in 1:length(x)
        o.β[j] -= γ * alg(o).G[j]
    end
    nothing
end
