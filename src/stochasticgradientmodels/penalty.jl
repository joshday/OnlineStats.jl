#----------------------------------------------------------------------# Penalty
# None
immutable NoPenalty <: Penalty end


"An L2 (ridge) penalty on the coefficients"
immutable L2Penalty <: Penalty
    λ::Float64
    function L2Penalty(λ::Real)
        @assert λ >= 0
        @compat new(Float64(λ))
    end
end


"An L1 (LASSO) penalty on the coefficients"
immutable L1Penalty <: Penalty
    λ::Float64
    function L1Penalty(λ::Real)
        @assert λ >= 0
        new(@compat Float64(λ))
    end
end


"A weighted average of L1 and L2 penalties on the coefficients"
immutable ElasticNetPenalty <: Penalty
    λ::Float64
    α::Float64
    function ElasticNetPenalty(λ::Real, α::Real)
        @assert 0 <= α <= 1
        @assert λ >= 0
        @compat new(Float64(λ), Float64(α))
    end
end


Base.show(io::IO, p::NoPenalty) = println(io, "  > Penalty:     NoPenalty")
Base.show(io::IO, p::L2Penalty) = println(io, "  > Penalty:     L2Penalty, λ = ", p.λ)
Base.show(io::IO, p::L1Penalty) = println(io, "  > Penalty:     L1Penalty, λ = ", p.λ)
Base.show(io::IO, p::ElasticNetPenalty) = println(io, "  > Penalty:     ElasticNetPenalty, λ = ", p.λ, ", α = ", p.α)
