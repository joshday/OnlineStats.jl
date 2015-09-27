#-------------------------------------------------------# Type and Constructors
"""
Approximate quantiles using an online MM algorithm.
"""
type QuantileMM <: OnlineStat
    q::VecF              # Quantile estimates
    τ::VecF                # tau values

    s::VecF                # sufficients stats for MM (s, t, and o)
    t::VecF
    o::Float64

    n::Int64              # number of observations used
    weighting::LearningRate

    function QuantileMM(q::VecF, τ::VecF, s::VecF, t::VecF, o::Float64, n::Int64, wgt::LearningRate)
        all([τ[i] < 1 && τ[i] > 0 for i in 1:length(τ)]) || error("τ must be in (0, 1)")
        n >= 0 || error("n must be nonnegative")
        new(q, τ, s, t, o, n, wgt)
    end
end

function QuantileMM(y::AVecF,
                    wgt::LearningRate = LearningRate(r = .51);
                    τ::VecF = [.25, .5, .75],
                    start::VecF = quantile(y, τ))
    o = QuantileMM(wgt, τ = τ, start = start)
    update!(o, y)
    o
end

function QuantileMM(wgt::LearningRate = LearningRate(r = .51);
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
    γ = weight(o)
    o.o = smooth(o.o, 1.0, γ)
    o.n += 1
    for j in 1:length(o.τ)
        w::Float64 = 1.0 / abs(y - o.q[j])
        o.s[j] = smooth(o.s[j], w * y, γ)
        o.t[j] = smooth(o.t[j], w, γ)
        o.q[j] = (o.s[j] + o.o * (2 * o.τ[j] - 1)) / o.t[j]
    end
end


function updatebatch!(o::QuantileMM, y::AVecF)
    γ = weight(o)
    n = length(y)
    @compat o.o = smooth(o.o, Float64(n), γ)

    for i in 1:length(o.τ)
        # Update sufficient statistics
        w::Vector = abs(y - o.q[i]) .^ -1
        o.s[i] = smooth(o.s[i], sum(w .* y), γ)
        o.t[i] = smooth(o.t[i], sum(w), γ)
        # Update quantile
        o.q[i] = (o.s[i] + o.o * (2 * o.τ[i] - 1)) / o.t[i]
    end

    o.n += n
    return
end
