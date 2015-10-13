# TODO: Minimax Concave Penalty
# http://arxiv.org/pdf/1002.4734.pdf

#----------------------------------------------------------------------# Penalty
"No penalty on the coefficients"
immutable NoPenalty <: Penalty end
Base.show(io::IO, p::NoPenalty) = println(io, "NoPenalty")
@inline _j(p::NoPenalty, β::VecF) = 0.0
@inline prox(βj::Float64, p::NoPenalty, s::Float64) = βj


"An L2 (ridge) penalty on the coefficients"
type L2Penalty <: Penalty
    λ::Float64
    function L2Penalty(λ::Real)
        @assert λ >= 0
        @compat new(Float64(λ))
    end
end
Base.show(io::IO, p::L2Penalty) = println(io, "L2Penalty(λ = $(p.λ))")
@inline _j(p::L2Penalty, β::VecF) = sumabs2(β)
# @inline function prox(βj::Float64, p::L2Penalty, s::Float64)
#     βj / (1.0 + s * p.λ)
# end


"An L1 (LASSO) penalty on the coefficients"
type L1Penalty <: Penalty
    λ::Float64
    function L1Penalty(λ::Real)
        @assert λ >= 0
        new(@compat Float64(λ))
    end
end
Base.show(io::IO, p::L1Penalty) = println(io, "L1Penalty(λ = $(p.λ))")
@inline _j(p::L1Penalty, β::VecF) = sumabs(β)
@inline prox(βj::Float64, p::L1Penalty, s::Float64) = sign(βj) * max(abs(βj) - s * p.λ, 0.0)


"A weighted average of L1 and L2 penalties on the coefficients"
type ElasticNetPenalty <: Penalty
    λ::Float64
    α::Float64
    function ElasticNetPenalty(λ::Real, α::Real)
        @assert 0 <= α <= 1
        @assert λ >= 0
        @compat new(Float64(λ), Float64(α))
    end
end
Base.show(io::IO, p::ElasticNetPenalty) = println(io, "ElasticNetPenalty(λ = $(p.λ), α = $(p.α))")
@inline _j(p::ElasticNetPenalty, β::VecF) = p.λ * (p.α * sumabs(β) + (1 - p.α) * .5 * sumabs2(β))
@inline function prox(βj::Float64, p::ElasticNetPenalty, s::Float64)
    βj = sign(βj) * max(abs(βj) - s * p.λ * p.α, 0.0)  # Lasso prox
    βj = βj / (1.0 + s * p.λ * (1.0 - p.α))            # Ridge prox
end


# http://www.pstat.ucsb.edu/student%20seminar%20doc/SCAD%20Jian%20Shi.pdf
"Smoothly Clipped Absolute Devation penalty on the coefficients"
type SCADPenalty <: Penalty
    λ::Float64
    a::Float64
    function SCADPenalty(λ::Real, a::Real = 3.7)  # 3.7 is what Fan and Li use
        @assert λ >= 0
        @assert a > 2
        @compat new(Float64(λ), Float64(a))
    end
end
Base.show(io::IO, p::SCADPenalty) = println(io, "SCADPenalty(λ = $(p.λ), a = $(p.a))")
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
@inline function prox(βj::Float64, p::SCADPenalty, s::Float64)
    if abs(βj) > p.a * p.λ
    elseif abs(βj) < 2.0 * p.λ
        βj = sign(βj) * max(abs(βj) - s * p.λ, 0.0)
    else
        βj = (βj - s * sign(βj) * p.a * p.λ / (p.a - 1.0)) / (1.0 - (1.0 / p.a - 1.0))
    end
    βj
end


#-----------------------------------------------------------------------# common
Base.copy(p::Penalty) = deepcopy(p)

# Prox operator is only needed for nondifferentiable penalties
# s = step size
@inline function prox!(β::AVecF, p::Penalty, s::Float64)
    for j in 1:length(β)
        β[j] = prox(β[j], p, s)
    end
end
