abstract Penalty
#--------------------------------------------------------------------# NoPenalty
immutable NoPenalty <: Penalty end
Base.show(io::IO, p::NoPenalty) = print(io, "NoPenalty")
add_deriv(p::NoPenalty, g, βj) = g
_j(p::NoPenalty, β) = 0.0
prox(p::NoPenalty, βj::Float64, s::Float64) = βj

#--------------------------------------------------------------------# L2Penalty
type L2Penalty <: Penalty
    λ::Float64
    function L2Penalty(λ::Real)
        @assert λ >= 0
        new(Float64(λ))
    end
end
Base.show(io::IO, p::L2Penalty) = print(io, "L2Penalty (λ = $(p.λ))")
add_deriv(p::L2Penalty, g, βj) = g + p.λ * βj
_j(p::L2Penalty, β) = 0.5 * p.λ * sumabs2(β)
prox(p::L2Penalty, βj::Float64, s::Float64) = βj / (1.0 + s * p.λ)

#--------------------------------------------------------------------# L1Penalty
type L1Penalty <: Penalty
    λ::Float64
    function L1Penalty(λ::Real)
        @assert λ >= 0
        new(Float64(λ))
    end
end
Base.show(io::IO, p::L1Penalty) = print(io, "L1Penalty (λ = $(p.λ))")
add_deriv(p::L1Penalty, g, βj) = g + p.λ * sign(βj)
_j(p::L1Penalty, β) = p.λ * sumabs(β)
prox(p::L1Penalty, βj::Float64, s::Float64) = sign(βj) * max(abs(βj) - s * p.λ, 0.0)


#------------------------------------------------------------# ElasticNetPenalty
type ElasticNetPenalty <: Penalty
    λ::Float64
    α::Float64
    function ElasticNetPenalty(λ::Real, α::Real = 0.5)
        @assert λ >= 0
        @assert 0 <= α <= 1
        new(Float64(λ), Float64(α))
    end
end
Base.show(io::IO, p::ElasticNetPenalty) = print(io, "ElasticNetPenalty (λ = $(p.λ), α = $(p.α))")
add_deriv(p::ElasticNetPenalty, g, βj) = g + p.λ * (p.α * sign(βj) + (1.0 - p.α) * βj)
_j(p::ElasticNetPenalty, β) = p.λ * (p.α * sumabs(β) + (1. - p.α) * 0.5 * sumabs2(β))
function prox(p::ElasticNetPenalty, βj::Float64, s::Float64)
    βj = sign(βj) * max(abs(βj) - s * p.λ * p.α, 0.0)  # Lasso prox
    βj = βj / (1.0 + s * p.λ * (1.0 - p.α))            # Ridge prox
end


#------------------------------------------------------------------# SCADPenalty
# http://www.pstat.ucsb.edu/student%20seminar%20doc/SCAD%20Jian%20Shi.pdf
type SCADPenalty <: Penalty
    λ::Float64
    a::Float64
    function SCADPenalty(λ::Real, a::Real = 3.7)  # 3.7 is what Fan and Li use
        @assert a > 2
        @assert λ >= 0
        new(Float64(λ), Float64(a))
    end
end
Base.show(io::IO, p::SCADPenalty) = print(io, "SCADPenalty (λ = $(p.λ), a = $(p.a))")
function add_deriv(p::SCADPenalty, g, βj)
    if abs(βj) < p.λ
        g + sign(βj) * p.λ
    elseif abs(βj) < p.a * p.λ
        g + max(p.a * p.λ - abs(βj), 0.0) / (p.a - 1.0)
    else
        g
    end
end
function _j(p::SCADPenalty, β)
    val = 0.0
    for j in 1:length(β)
        βj = abs(β[j])
        if βj < p.λ
            val += p.λ * βj
        elseif βj < p.λ * p.a
            val -= 0.5 * (βj ^ 2 - 2.0 * p.a * p.λ * βj + p.λ ^ 2) / (p.a - 1.0)
        else
            val += 0.5 * (p.a + 1.0) * p.λ ^ 2
        end
    end
    return val
end
function prox(p::SCADPenalty, βj::Float64, s::Float64)
    if abs(βj) > p.a * p.λ
    elseif abs(βj) < 2.0 * p.λ
        βj = sign(βj) * max(abs(βj) - s * p.λ, 0.0)
    else
        βj = (βj - s * sign(βj) * p.a * p.λ / (p.a - 1.0)) / (1.0 - (1.0 / p.a - 1.0))
    end
    βj
end



function prox!(p::Penalty, β::AVecF, s::Float64)
    for j in 1:length(β)
        β[j] = prox(p, β[j], s)
    end
end
