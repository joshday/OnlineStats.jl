#-------------------------------------------------------# Type and Constructors
type QuantileMM <: ScalarStat
    est::Vector{Float64}              # Quantiles
    τ::Vector{Float64}                # tau values
    r::Float64                        # learning rate
    s::Vector{Float64}                # sufficients stats for MM (s, t, and o)
    t::Vector{Float64}
    o::Float64
    n::Int64                          # number of observations used
    nb::Int64                         # number of batches used
end

function QuantileMM(y::Vector; τ::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.6)
    p::Int = length(τ)
    qs::Vector{Float64} = quantile(y, τ) + .00000001
    s::Vector{Float64} = [sum(abs(y - qs[i]) .^ -1 .* y) for i in 1:p]
    t::Vector{Float64} = [sum(abs(y - qs[i]) .^ -1) for i in 1:p]
    o::Float64 = length(y)
    qs = [(s[i] + o * (2 * τ[i] - 1)) / t[i] for i in 1:p]

    QuantileMM(qs, τ, r, s, t, o, length(y), 1)
end

QuantileMM(y::Real; args...) = QuantileMM([y], args)


#-------------------------------------------------------------# param and value
param(obj::QuantileMM) = [symbol("τ_$i") for i in obj.τ]

value(obj::QuantileMM) = copy(obj.est)


#---------------------------------------------------------------------# update!
function update!(obj::QuantileMM, y::Vector)
    γ::Float64 = obj.nb ^ - obj.r
    n = length(y)

    for i in 1:length(obj.τ)
        # Update sufficient statistics
        w::Vector = abs(y - obj.est[i]) .^ -1
        obj.s[i] += γ * (sum(w .* y) - obj.s[i])
        obj.t[i] += γ * (sum(w) - obj.t[i])
        obj.o += γ * (n - obj.o)
        # Update quantile
        obj.est[i] = (obj.s[i] + obj.o * (2 * obj.τ[i] - 1)) / obj.t[i]
    end

    obj.n = obj.n + n
    obj.nb += 1
end

update!(obj::QuantileMM, y::Real) = update!(obj, [y])


#------------------------------------------------------------------------# Base
Base.copy(obj::QuantileMM) = QuantileMM(obj.est, obj.τ, obj.r, obj.n, obj.nb)
