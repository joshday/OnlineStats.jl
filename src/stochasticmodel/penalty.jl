# TODO: Minimax Concave Penalty: http://arxiv.org/pdf/1002.4734.pdf

#--------------------------------------------------------------------# Template
#===============================================================================
To make a new penalty type universally accessible within OnlineStats:

- type must be mutable with tuning parameter λ
    - this is used for automatic fitting algorithms
- A one line Base.show method
    - this is used in the Base.show method for StochasticModel
- A _j method, the value of the penalty
    - this is used in evaluating convergence criteria for SparseReg
- A prox method, the prox operator with tradeoff parameter s: prox_{sj}(βⱼ)
    - this gets used by SparseReg and ProxGrad
- an add∇j method: adds penalty subgradient to loss subgradient at index i
    - this gets used by SGD, SGDSparse, MM
===============================================================================#

#--------------------------------------------------------------------# NoPenalty
"No penalty on the coefficients"
immutable NoPenalty <: Penalty end
Base.show(io::IO, p::NoPenalty) = print(io, "NoPenalty")
@inline _j(p::NoPenalty, β::VecF) = 0.0
@inline prox(p::NoPenalty, βj::Float64, s::Float64) = βj
@inline add∇j(::NoPenalty, g::Float64, β::VecF, i::Int) = g

#--------------------------------------------------------------------# L2Penalty
"An L2 (ridge) penalty on the coefficients"
type L2Penalty <: Penalty
    λ::Float64
    function L2Penalty(λ::Real)
        @assert λ >= 0
        new(Float64(λ))
    end
end
Base.show(io::IO, p::L2Penalty) = print(io, "L2Penalty(λ = $(p.λ))")
@inline _j(p::L2Penalty, β::VecF) = p.λ * sumabs2(β)
@inline prox(p::L2Penalty, βj::Float64, s::Float64) = βj / (1.0 + s * p.λ)
@inline add∇j(p::L2Penalty, g::Float64, β::VecF, i::Int) = g + p.λ * β[i]

#--------------------------------------------------------------------# L1Penalty
"An L1 (LASSO) penalty on the coefficients"
type L1Penalty <: Penalty
    λ::Float64
    function L1Penalty(λ::Real)
        @assert λ >= 0
        new(Float64(λ))
    end
end
Base.show(io::IO, p::L1Penalty) = print(io, "L1Penalty(λ = $(p.λ))")
@inline _j(p::L1Penalty, β::VecF) = p.λ * sumabs(β)
@inline prox(p::L1Penalty, βj::Float64, s::Float64) = sign(βj) * max(abs(βj) - s * p.λ, 0.0)
@inline add∇j(p::L1Penalty, g::Float64, β::VecF, i::Int) = g + p.λ * sign(β[i])

#------------------------------------------------------------# ElasticNetPenalty
"A weighted average of L1 and L2 penalties on the coefficients"
type ElasticNetPenalty <: Penalty
    λ::Float64
    α::Float64
    function ElasticNetPenalty(λ::Real, α::Real)
        @assert 0 <= α <= 1
        @assert λ >= 0
        new(Float64(λ), Float64(α))
    end
end
Base.show(io::IO, p::ElasticNetPenalty) = print(io, "ElasticNetPenalty(λ = $(p.λ), α = $(p.α))")
@inline _j(p::ElasticNetPenalty, β::VecF) = p.λ * (p.α * sumabs(β) + (1 - p.α) * .5 * sumabs2(β))
@inline function prox(p::ElasticNetPenalty, βj::Float64, s::Float64)
    βj = sign(βj) * max(abs(βj) - s * p.λ * p.α, 0.0)  # Lasso prox
    βj = βj / (1.0 + s * p.λ * (1.0 - p.α))            # Ridge prox
end
@inline add∇j(p::ElasticNetPenalty, g::Float64, β::VecF, i::Int) = g + p.λ * (p.α * sign(β[i]) + (1 - p.α) * β[i])

#------------------------------------------------------------------# SCADPenalty
# http://www.pstat.ucsb.edu/student%20seminar%20doc/SCAD%20Jian%20Shi.pdf
"Smoothly Clipped Absolute Devation penalty on the coefficients"
type SCADPenalty <: Penalty
    λ::Float64
    a::Float64
    function SCADPenalty(λ::Real, a::Real = 3.7)  # 3.7 is what Fan and Li use
        @assert λ >= 0
        @assert a > 2
        new(Float64(λ), Float64(a))
    end
end
Base.show(io::IO, p::SCADPenalty) = print(io, "SCADPenalty(λ = $(p.λ), a = $(p.a))")
@inline function _j(p::SCADPenalty, β::VecF)
    val = 0.0
    for j in 1:length(β)
        βj = abs(β[j])
        if βj < p.λ
            val += p.λ * βj
        elseif βj < p.λ * p.a
            val -= 0.5 * (βj^2 - 2.0 * p.a * p.λ * βj + p.λ^2) / (p.a - 1.0)
        else
            val += 0.5 * (p.a + 1.0) * p.λ^2
        end
    end
    return val
end
@inline function prox(p::SCADPenalty, βj::Float64, s::Float64)
    if abs(βj) > p.a * p.λ
    elseif abs(βj) < 2.0 * p.λ
        βj = sign(βj) * max(abs(βj) - s * p.λ, 0.0)
    else
        βj = (βj - s * sign(βj) * p.a * p.λ / (p.a - 1.0)) / (1.0 - (1.0 / p.a - 1.0))
    end
    βj
end
@inline function add∇j(p::SCADPenalty, g::Float64, β::VecF, i::Int)
    if abs(β[i]) < p.λ
        g + sign(β[i]) * p.λ
    elseif abs(β[i]) < p.a * p.λ
        g + max(p.a * p.λ - abs(β[i]), 0.0) / (p.a - 1.0)
    else
        g
    end
end

#-----------------------------------------------------------------------# common
Base.copy(p::Penalty) = deepcopy(p)

# Prox operator is only needed for nondifferentiable penalties
# s = step size
# prox_{s*g}(β) = argmin_u (g(u) + 1/(2s) * (u - β)^2)
@inline function prox!(p::Penalty, β::AVecF, s::Float64)
    for j in 1:length(β)
        β[j] = prox(p, β[j], s)
    end
end
