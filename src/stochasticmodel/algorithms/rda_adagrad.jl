#--------------------------------------------------------------------------# RDA
"Regularized Dual Averaging with ADAGRAD weights"
type RDA <: Algorithm
    G0::Float64     # sum of squared gradients for intercept
    G::VecF         # sum of squared gradients for everything else
    Ḡ0::Float64     # avg gradient for intercept
    Ḡ::VecF         # avg gradient for everything else
    η::Float64      # constant step size
    n_updates::Int  # number of updates (nobs(o), unless calling updatebatch!)
    function RDA(;η::Real = 1.0, δ::Real = 1e-8)
        @assert η > 0
        @assert δ > 0
        new(Float64(δ), zeros(2), 0.0, zeros(2), Float64(η), 0)
    end
end

Base.show(io::IO, o::RDA) = print(io, "RDA(η = $(o.η))")

function updateβ!(o::StochasticModel{RDA}, x::AVecF, y::Float64)
    if nobs(o) == 1
        alg(o).G = zeros(length(x)) + alg(o).G0
        alg(o).Ḡ = zeros(length(x)) + alg(o).G0
    end

    g = ∇f(o.model, y, predict(o, x))

    w = 1 / nobs(o)
    if o.intercept
        alg(o).G0 += g^2
        alg(o).Ḡ0 += w * (g - alg(o).Ḡ0)
        o.β0 = -weight(o) * alg(o).Ḡ0
    end

    @inbounds for j in 1:length(x)
        gj = g * x[j]
        alg(o).G[j] += gj^2
        alg(o).Ḡ[j] += w * (gj - alg(o).Ḡ[j])
        rda_update!(o, j)
    end
    alg(o).n_updates += 1
end

function updatebatchβ!(o::StochasticModel{RDA}, x::AMatF, y::AVecF)
    if alg(o).G == zeros(2) # on first update, set the size of o.algorithm.G
        alg(o).G = zeros(size(x, 2)) + alg(o).G0
        alg(o).Ḡ = zeros(size(x, 2)) + alg(o).G0
    end

    n = length(y)
    ŷ = predict(o, x)

    alg(o).n_updates += 1
    w = 1 / n_updates(o)
    if o.intercept
        g = 0.0
        for i in 1:n
            g += ∇f(o.model, y[i], ŷ[i])
        end
        g /= n
        alg(o).G0 += g ^ 2
        alg(o).Ḡ0 += w * (g - alg(o).Ḡ0)
        o.β0 = -weight(o) * alg(o).Ḡ0
    end

    for j in 1:size(x, 2)
        g = 0.0
        for i in 1:n
            g += x[i, j] * ∇f(o.model, y[i], ŷ[i])
        end
        g /= n
        alg(o).G[j] += g ^ 2
        alg(o).Ḡ[j] += w * (g - alg(o).Ḡ[j])
        rda_update!(o, j)
    end
end

n_updates(o::StochasticModel{RDA}) = alg(o).n_updates
@inline weight(o::StochasticModel{RDA}, j::Int) = n_updates(o) * alg(o).η / sqrt(alg(o).G[j])

# NoPenalty
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{RDA,M,NoPenalty}, j::Int)
    o.β[j] = -weight(o, j) * alg(o).Ḡ[j]
end

# L2Penalty
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{RDA,M,L2Penalty}, j::Int)
    alg(o).Ḡ[j] += (1 / n_updates(o)) * pen(o).λ * o.β[j]
    o.β[j] = -weight(o, j) * alg(o).Ḡ[j]
end

# L1Penalty (http://www.magicbroom.info/Papers/DuchiHaSi10.pdf)
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{RDA,M,L1Penalty}, j::Int)
    if abs(alg(o).Ḡ[j]) < pen(o).λ
        o.β[j] = 0.0
    else
        ḡ = alg(o).Ḡ[j]
        o.β[j] = sign(-ḡ) * weight(o, j)  * (abs(ḡ) - pen(o).λ)
    end
end

# ElasticNetPenalty
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{RDA,M,ElasticNetPenalty}, j::Int)
    alg(o).Ḡ[j] += (1 / n_updates(o)) * pen(o).λ * (1 - pen(o).λ) * o.β[j]
    λ = pen(o).λ * pen(o).α
    if abs(alg(o).Ḡ[j]) < λ
        o.β[j] = 0.0
    else
        ḡ = alg(o).Ḡ[j]
        o.β[j] = sign(-ḡ) * weight(o, j) * (abs(ḡ) - λ)
    end
end

# SCADPenalty
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{RDA,M,SCADPenalty}, j::Int)
    error("SCADPenalty is not implemented yet for RDA")
end
