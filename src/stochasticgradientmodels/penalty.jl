# TODO: Minimax Concave Penalty
# http://arxiv.org/pdf/1002.4734.pdf

#----------------------------------------------------------------------# Penalty
Base.copy(p::Penalty) = deepcopy(p)

"No penalty on the coefficients"
immutable NoPenalty <: Penalty end
Base.show(io::IO, p::NoPenalty) = println(io, "  > Penalty:     NoPenalty")
@inline _j(p::NoPenalty, β::VecF) = 0.0

"An L2 (ridge) penalty on the coefficients"
type L2Penalty <: Penalty
    λ::Float64
    function L2Penalty(λ::Real)
        @assert λ >= 0
        @compat new(Float64(λ))
    end
end
Base.show(io::IO, p::L2Penalty) = println(io, "  > Penalty:     L2Penalty, λ = ", p.λ)
@inline _j(p::L2Penalty, β::VecF) = sumabs2(β)


"An L1 (LASSO) penalty on the coefficients"
type L1Penalty <: Penalty
    λ::Float64
    function L1Penalty(λ::Real)
        @assert λ >= 0
        new(@compat Float64(λ))
    end
end
Base.show(io::IO, p::L1Penalty) = println(io, "  > Penalty:     L1Penalty, λ = ", p.λ)
@inline _j(p::L1Penalty, β::VecF) = sumabs(β)


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
Base.show(io::IO, p::ElasticNetPenalty) = println(io, "  > Penalty:     ElasticNetPenalty, λ = ", p.λ, ", α = ", p.α)
@inline _j(p::ElasticNetPenalty, β::VecF) = p.λ * (p.α * sumabs(β) + (1 - p.α) * .5 * sumabs2(β))


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
Base.show(io::IO, p::SCADPenalty) = println(io, "  > Penalty:     SCADPenalty, λ = ", p.λ, ", a = ", p.a)
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
