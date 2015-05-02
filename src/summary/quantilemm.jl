#-------------------------------------------------------# Type and Constructors
type QuantileMM <: OnlineStat
    est::VecF              # Quantile estimates
    τ::VecF                # tau values
    r::Float64             # learning rate
    s::VecF                # sufficients stats for MM (s, t, and o)
    t::VecF
    o::Float64
    n::Int64              # number of observations used
    nb::Int64             # number of batches used
    weighting::StochasticWeighting
end

function QuantileMM(y::Vector; τ::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.6)
    p = length(τ)
    qs::Vector{Float64} = quantile(y, τ) + .00000001
    s::Vector{Float64} = [sum(abs(y - qs[i]) .^ -1 .* y) for i in 1:p]
    t::Vector{Float64} = [sum(abs(y - qs[i]) .^ -1) for i in 1:p]
    o::Float64 = length(y)
    qs = [(s[i] + o * (2 * τ[i] - 1)) / t[i] for i in 1:p]

    QuantileMM(qs, τ, r, s, t, o, length(y), 1)
end

QuantileMM(y::Real; args...) = QuantileMM([y], args...)


#-----------------------------------------------------------------------# state
state_names(o::QuantileMM) = [:quantiles, :nobs]

state(o::QuantileMM) = Any[o.est, nobs(o)]


#---------------------------------------------------------------------# update!
function update!(o::QuantileMM, y::Vector)
    γ::Float64 = o.nb ^ - o.r
    n = length(y)
    o.o = smooth(o.o, n, γ)

    for i in 1:length(o.τ)
        # Update sufficient statistics
        w::Vector = abs(y - o.est[i]) .^ -1
        o.s[i] = smooth(o.s[i], w'y, γ)
        o.t[i] = smooth(o.t[i], sum(w), γ)
#         o.s[i] += γ * (sum(w .* y) - o.s[i])
#         o.t[i] += γ * (sum(w) - o.t[i])
#         o.o += γ * (n - o.o)
        # Update quantile
        o.est[i] = (o.s[i] + o.o * (2 * o.τ[i] - 1)) / o.t[i]
    end

    o.n = o.n + n
    o.nb += 1
end

update!(o::QuantileMM, y::Real) = update!(o, [y])


#------------------------------------------------------------------------# Base
Base.copy(o::QuantileMM) = QuantileMM(o.est, o.τ, o.r, o.n, o.nb)
