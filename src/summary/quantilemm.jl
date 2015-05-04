#-------------------------------------------------------# Type and Constructors
type QuantileMM <: OnlineStat
    q::VecF              # Quantile qimates
    τ::VecF                # tau values

    s::VecF                # sufficients stats for MM (s, t, and o)
    t::VecF
    o::Float64

    n::Int64              # number of observations used
    weighting::StochasticWeighting
end

function QuantileMM(y::VecF,
                    wgt::StochasticWeighting = StochasticWeighting();
                    τ::VecF = [.25, .5, .75],
                    start::VecF = quantile(y, τ))
    o = QuantileMM(wgt, τ = τ, start = start)
    update!(o, y)
    o
end

function QuantileMM(y::Float64,
                    wgt::StochasticWeighting = StochasticWeighting();
                    τ::VecF = [.25, .5, .75],
                    start::VecF = zeros(length(τ)))
    QuantileMM([y], wgt, τ = τ, start = start)
end

function QuantileMM(wgt::StochasticWeighting = StochasticWeighting();
                    τ = [.25, .5, .75],
                    start::VecF = zeros(length(τ)))
    p = length(τ)
    QuantileMM(start, τ, zeros(p), zeros(p), 0., 0, wgt)
end


#-----------------------------------------------------------------------# state
statenames(o::QuantileMM) = [:quantiles, :τ, :nobs]
state(o::QuantileMM) = Any[copy(o.q), o.τ, nobs(o)]


#---------------------------------------------------------------------# update!
function update!(o::QuantileMM, y::Float64)
    γ = weight!(o)
    o.o = smooth(o.o, 1., γ)
    o.n += 1
    for j in 1:length(o.τ)
        w::Float64 = 1 / abs(y - o.q[j])
        o.s[j] = smooth(o.s[j], w * y, γ)
        o.t[j] = smooth(o.t[j], w, γ)
        o.q[j] = (o.s[j] + o.o * (2 * o.τ[j] - 1)) / o.t[j]
    end
end


function updatebatch!(o::QuantileMM, y::VecF)
    γ = weight!(o)
    n = length(y)
    o.o = smooth(o.o, n, γ)

    for i in 1:length(o.τ)
        # Update sufficient statistics
        w::Vector = abs(y - o.q[i]) .^ -1
        o.s[i] = smooth(o.s[i], w'y, γ)
        o.t[i] = smooth(o.t[i], sum(w), γ)
#         o.s[i] += γ * (sum(w .* y) - o.s[i])
#         o.t[i] += γ * (sum(w) - o.t[i])
#         o.o += γ * (n - o.o)
        # Update quantile
        o.q[i] = (o.s[i] + o.o * (2 * o.τ[i] - 1)) / o.t[i]
    end

    o.n += n
    o.nb += 1
end


