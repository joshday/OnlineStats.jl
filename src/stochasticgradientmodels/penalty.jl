#----------------------------------------------------------------------# Penalty
Base.copy(p::Penalty) = deepcopy(p)
penalty(o::SGModel) = copy(o.penalty)

"No penalty on the coefficients"
immutable NoPenalty <: Penalty end
Base.show(io::IO, p::NoPenalty) = println(io, "  > Penalty:     NoPenalty")

"An L2 (ridge) penalty on the coefficients"
type L2Penalty <: Penalty
    λ::Float64
    function L2Penalty(λ::Real)
        @assert λ >= 0
        @compat new(Float64(λ))
    end
end
Base.show(io::IO, p::L2Penalty) = println(io, "  > Penalty:     L2Penalty, λ = ", p.λ)


"An L1 (LASSO) penalty on the coefficients"
type L1Penalty <: Penalty
    λ::Float64
    function L1Penalty(λ::Real)
        @assert λ >= 0
        new(@compat Float64(λ))
    end
end
Base.show(io::IO, p::L1Penalty) = println(io, "  > Penalty:     L1Penalty, λ = ", p.λ)


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
