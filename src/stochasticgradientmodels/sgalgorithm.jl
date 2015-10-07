#------------------------------------------------------------------# SGAlgorithm
alg(o) = o.algorithm
pen(o) = o.penalty

#--------------------------------------------------------------------------# SGD
"Stochastic (Sub)Gradient Descent"
immutable SGD <: SGAlgorithm   # step size is γ = η * nobs ^ -r
    η::Float64
    r::Float64
    function SGD(;η::Real = 1.0, r::Real = .5)
        @assert η > 0
        @assert 0 < r < 1
        @compat new(Float64(η), Float64(r))
    end
end
@inline function updateβ!{M<:ModelDefinition, P<:Penalty}(o::SGModel{SGD,M,P}, x::AVecF, y::Float64)
    yhat = predict(o, x)
    ε = y - yhat

    γ = alg(o).η / nobs(o) ^ alg(o).r

    if o.intercept
        o.β0 -= γ * ∇f(o.model, ε, 1.0, y, yhat)
    end

    @inbounds for j in 1:length(x)
        g = ∇f(o.model, ε, x[j], y, yhat)
        o.β[j] -= γ * add∇j(g, pen(o), o.β, j)
    end
    nothing
end

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

#---------------------------------------------------------------------# ProxGrad
# θ_t = argmin(η * g'θ + η * J(θ) + B_ψ(θ, θ_t))  where  ψ = .5 * θ' * H * θ
"Proximal Gradient Method with ADAGRAD weights"
type ProxGrad <: SGAlgorithm
    G0::Float64     # sum of squared gradients for intercept
    G::VecF         # sum of squared gradients for everything else
    η::Float64      # constant step size
    δ::Float64      # ensure we don't divide by 0
    @compat function ProxGrad(;η::Real = 1.0, δ::Real = 1e-8)
        @assert η > 0
        @assert δ > 0
        new(0.0, zeros(2), Float64(η), Float64(δ))
    end
end
@inline function updateβ!{M<:ModelDefinition, P<:Penalty}(o::SGModel{ProxGrad,M,P}, x::AVecF, y::Float64)
    if nobs(o) == 1
        alg(o).G = zeros(length(x))
    end
    yhat = predict(o, x)
    ε = y - yhat
    t = nobs(o)

    if o.intercept
        g = ∇f(o.model, ε, 1.0, y, yhat)
        alg(o).G0 += g^2
        if alg(o).G0 != 0.0
            o.β0 -= alg(o).η * g / (alg(o).δ + sqrt(alg(o).G0))
        end
    end

    @inbounds for j in 1:length(x)
        g = ∇f(o.model, ε, x[j], y, yhat)
        alg(o).G[j] += g^2
        adagrad_update!(o, g, j)
    end
    nothing
end

# L2Penalty
@inline function adagrad_update!{M<:ModelDefinition}(o::SGModel{ProxGrad,M,L2Penalty}, g::Float64, j::Int)
    o.β[j] -= alg(o).η * (g + pen(o).λ * o.β[j]) / (alg(o).δ + sqrt(alg(o).G[j]))
end

# nondifferentiable penalties and NoPenalty
@inline function adagrad_update!{M<:ModelDefinition, P<:Penalty}(o::SGModel{ProxGrad,M,P}, g::Float64, j::Int)
    h = alg(o).η / (alg(o).δ + sqrt(alg(o).G[j]))
    o.β[j] = prox(o.β[j] - g * h, pen(o), h)
end




#--------------------------------------------------------------------------# RDA
"Regularized Dual Averaging with ADAGRAD weights"
type RDA <: SGAlgorithm
    G0::Float64     # sum of squared gradients for intercept
    G::VecF         # sum of squared gradients for everything else
    Ḡ0::Float64     # avg gradient for intercept
    Ḡ::VecF         # avg gradient for everything else
    η::Float64      # constant step size
    δ::Float64      # ensure we don't divide by 0
    @compat function RDA(;η::Real = 1.0, δ::Real = 1e-8)
        @assert η > 0
        @assert δ > 0
        new(0.0, zeros(2), 0.0, zeros(2), Float64(η), Float64(δ))
    end
end
@inline function updateβ!{M<:ModelDefinition, P<:Penalty}(o::SGModel{RDA,M,P}, x::AVecF, y::Float64)
    if nobs(o) == 1
        alg(o).G = zeros(length(x))
        alg(o).Ḡ = zeros(length(x))
    end

    yhat = predict(o, x)
    ε = y - yhat

    w = (nobs(o) - 1) / nobs(o)
    if o.intercept
        g = ∇f(o.model, ε, 1.0, y, yhat)
        alg(o).G0 += g^2
        alg(o).Ḡ0 = w * alg(o).Ḡ0 + (1 - w) * g
        o.β0 = -alg(o).η * nobs(o) * alg(o).Ḡ0 / (alg(o).δ + sqrt(alg(o).G0))
    end

    # update the average gradient
    α = nobs(o) / (nobs(o) + 1)
    @inbounds for j in 1:length(x)
        g = ∇f(o.model, ε, x[j], y, yhat)
        alg(o).G[j] += g^2
        alg(o).Ḡ[j] = w * alg(o).Ḡ[j] + (1 - w) * g
        rda_update!(o, g, j)
    end
    nothing
end

# I apologize to my future self for how hard this code is to read
# NoPenalty
@inline function rda_update!{M<:ModelDefinition}(o::SGModel{RDA,M,NoPenalty}, g::Float64, j::Int)
    o.β[j] = -nobs(o) * alg(o).η * alg(o).Ḡ[j] / (alg(o).δ + sqrt(alg(o).G[j]))
end

# L2Penalty
@inline function rda_update!{M<:ModelDefinition}(o::SGModel{RDA,M,L2Penalty}, g::Float64, j::Int)
    alg(o).Ḡ[j] += (1 / nobs(o)) * pen(o).λ * o.β[j]
    o.β[j] = -nobs(o) * alg(o).η * alg(o).Ḡ[j] / (alg(o).δ + sqrt(alg(o).G[j]))
end

# L1Penalty
# See original ADAGRAD paper
@inline function rda_update!{M<:ModelDefinition}(o::SGModel{RDA,M,L1Penalty}, g::Float64, j::Int)
    if abs(alg(o).Ḡ[j]) < pen(o).λ
        o.β[j] = 0.0
    else
        ḡ = alg(o).Ḡ[j]
        o.β[j] = sign(-ḡ) * alg(o).η * nobs(o)  * (abs(ḡ) - pen(o).λ)/ (alg(o).δ + sqrt(alg(o).G[j]))
    end
end

# ElasticNetPenalty
@inline function rda_update!{M<:ModelDefinition}(o::SGModel{RDA,M,ElasticNetPenalty}, g::Float64, j::Int)
    alg(o).Ḡ[j] += (1 / nobs(o)) * pen(o).λ * (1 - pen(o).λ) * o.β[j]
    λ = pen(o).λ * pen(o).α
    if abs(alg(o).Ḡ[j]) < λ
        o.β[j] = 0.0
    else
        ḡ = alg(o).Ḡ[j]
        o.β[j] = sign(-ḡ) * alg(o).η * nobs(o) * (abs(ḡ) - λ) / (alg(o).δ + sqrt(alg(o).G[j]))
    end
end

# SCADPenalty
@inline function rda_update!{M<:ModelDefinition}(o::SGModel{RDA,M,SCADPenalty}, g::Float64, j::Int)
    error("SCADPenalty is not implemented yet for RDA")
end
