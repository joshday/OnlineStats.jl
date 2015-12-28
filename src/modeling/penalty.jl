abstract Penalty
#--------------------------------------------------------------------# NoPenalty
immutable NoPenalty <: Penalty end
Base.show(io::IO, p::NoPenalty) = print(io, "NoPenalty")
add_deriv(p::NoPenalty, g, λ, βj) = g
_j(p::NoPenalty, λ, β) = 0.0
prox(p::NoPenalty, λ::Float64, βj::Float64, s::Float64) = βj

#--------------------------------------------------------------------# L2Penalty
immutable L2Penalty <: Penalty end
Base.show(io::IO, p::L2Penalty) = print(io, "L2Penalty")
add_deriv(p::L2Penalty, g, λ, βj) = g + λ * βj
_j(p::L2Penalty, λ, β) = 0.5 * λ * sumabs2(β)
prox(p::L2Penalty, λ::Float64, βj::Float64, s::Float64) = βj / (1.0 + s * λ)

#--------------------------------------------------------------------# L1Penalty
immutable L1Penalty <: Penalty end
Base.show(io::IO, p::L1Penalty) = print(io, "L1Penalty")
add_deriv(p::L1Penalty, g, λ, βj) = g + λ * sign(βj)
_j(p::L1Penalty, λ, β) = λ * sumabs(β)
function prox(p::L1Penalty, λ::Float64, βj::Float64, s::Float64)
    sign(βj) * max(abs(βj) - s * λ, 0.0)
end

#------------------------------------------------------------# ElasticNetPenalty
immutable ElasticNetPenalty <: Penalty
    α::Float64
    ElasticNetPenalty(a::Real = 0.5) = new(Float64(a))
end
Base.show(io::IO, p::ElasticNetPenalty) = print(io, "ElasticNetPenalty (α = $(p.α))")
add_deriv(p::ElasticNetPenalty, g, λ, βj) = g + λ * (p.α * sign(βj) + (1.0 - p.α) * βj)
_j(p::ElasticNetPenalty, λ, β) = λ * (p.α * sumabs(β) + (1. - p.α) * 0.5 * sumabs2(β))
function prox(p::ElasticNetPenalty, λ::Float64, βj::Float64, s::Float64)
    βj = sign(βj) * max(abs(βj) - s * λ * p.α, 0.0)  # Lasso prox
    βj = βj / (1.0 + s * λ * (1.0 - p.α))            # Ridge prox
end


#------------------------------------------------------------------# SCADPenalty
# http://www.pstat.ucsb.edu/student%20seminar%20doc/SCAD%20Jian%20Shi.pdf
type SCADPenalty <: Penalty
    a::Float64
    function SCADPenalty(a::Real = 3.7)  # 3.7 is what Fan and Li use
        @assert a > 2
        new(Float64(a))
    end
end
Base.show(io::IO, p::SCADPenalty) = print(io, "SCADPenalty (a = $(p.a))")
function add_deriv(p::SCADPenalty, g, λ, βj)
    if abs(βj) < λ
        g + sign(βj) * λ
    elseif abs(βj) < p.a * λ
        g + max(p.a * λ - abs(βj), 0.0) / (p.a - 1.0)
    else
        g
    end
end
function _j(p::SCADPenalty, λ, β)
    val = 0.0
    for j in 1:length(β)
        βj = abs(β[j])
        if βj < λ
            val += λ * βj
        elseif βj < λ * p.a
            val -= 0.5 * (βj ^ 2 - 2.0 * p.a * λ * βj + λ ^ 2) / (p.a - 1.0)
        else
            val += 0.5 * (p.a + 1.0) * λ ^ 2
        end
    end
    return val
end
function prox(p::SCADPenalty, λ, βj::Float64, s::Float64)
    if abs(βj) > p.a * λ
    elseif abs(βj) < 2.0 * λ
        βj = sign(βj) * max(abs(βj) - s * λ, 0.0)
    else
        βj = (βj - s * sign(βj) * p.a * λ / (p.a - 1.0)) / (1.0 - (1.0 / p.a - 1.0))
    end
    βj
end



function prox!(p::Penalty, λ::Float64, β::AVecF, s::Float64)
    for j in 1:length(β)
        β[j] = prox(p, λ, β[j], s)
    end
end
