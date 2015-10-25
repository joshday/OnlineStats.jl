#--------------------------------------------------------------------------# RDA
"Regularized Dual Averaging with ADAGRAD weights"
type RDA <: Algorithm
    G0::Float64     # sum of squared gradients for intercept
    G::VecF         # sum of squared gradients for everything else
    Ḡ0::Float64     # avg gradient for intercept
    Ḡ::VecF         # avg gradient for everything else
    η::Float64      # constant step size
    function RDA(;η::Real = 1.0, δ::Real = 1e-8)
        @assert η > 0
        @assert δ > 0
        new(Float64(δ), zeros(2), 0.0, zeros(2), Float64(η))
    end
end

Base.show(io::IO, o::RDA) = print(io, "RDA(η = $(o.η))")


function updateβ!(o::StochasticModel{RDA}, x::AVecF, y::Float64)
    if nobs(o) == 1
        alg(o).G = zeros(length(x)) + alg(o).G0
        alg(o).Ḡ = zeros(length(x)) + alg(o).G0
    end

    g = ∇f(o.model, y, predict(o, x))

    w = (nobs(o) - 1) / nobs(o)
    if o.intercept
        alg(o).G0 += g^2
        alg(o).Ḡ0 = w * alg(o).Ḡ0 + (1 - w) * g
        o.β0 = -alg(o).η * nobs(o) * alg(o).Ḡ0 / sqrt(alg(o).G0)
    end

    # update the average gradient
    @inbounds for j in 1:length(x)
        gj = g * x[j]
        alg(o).G[j] += gj^2
        alg(o).Ḡ[j] = w * alg(o).Ḡ[j] + (1 - w) * gj
        rda_update!(o, gj, j)
    end
end



weight(o::StochasticModel{RDA}, j::Int) = nobs(o) * alg(o).η / sqrt(alg(o).G[j])


# NoPenalty
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{RDA,M,NoPenalty}, g::Float64, j::Int)
    o.β[j] = -weight(o, j) * alg(o).Ḡ[j]
end

# L2Penalty
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{RDA,M,L2Penalty}, g::Float64, j::Int)
    alg(o).Ḡ[j] += (1 / nobs(o)) * pen(o).λ * o.β[j]
    o.β[j] = -weight(o, j) * alg(o).Ḡ[j]
end

# L1Penalty (http://www.magicbroom.info/Papers/DuchiHaSi10.pdf)
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{RDA,M,L1Penalty}, g::Float64, j::Int)
    if abs(alg(o).Ḡ[j]) < pen(o).λ
        o.β[j] = 0.0
    else
        ḡ = alg(o).Ḡ[j]
        o.β[j] = sign(-ḡ) * weight(o, j)  * (abs(ḡ) - pen(o).λ)
    end
end

# ElasticNetPenalty
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{RDA,M,ElasticNetPenalty}, g::Float64, j::Int)
    alg(o).Ḡ[j] += (1 / nobs(o)) * pen(o).λ * (1 - pen(o).λ) * o.β[j]
    λ = pen(o).λ * pen(o).α
    if abs(alg(o).Ḡ[j]) < λ
        o.β[j] = 0.0
    else
        ḡ = alg(o).Ḡ[j]
        o.β[j] = sign(-ḡ) * weight(o, j) * (abs(ḡ) - λ)
    end
end

# SCADPenalty
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{RDA,M,SCADPenalty}, g::Float64, j::Int)
    error("SCADPenalty is not implemented yet for RDA")
end
