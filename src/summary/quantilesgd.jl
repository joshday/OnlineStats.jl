#-------------------------------------------------------# Type and Constructors
type QuantileSGD{W <: Weighting} <: OnlineStat
    q::VecF              # Quantile estimates
    τ::VecF                # tau values (which quantiles)
    n::Int64               # number of observations used
    weighting::W
end

function QuantileSGD(y::VecF,
                     wgt::StochasticWeighting = StochasticWeighting();
                     τ::VecF = [.25, .5, .75],
                     start::VecF = quantile(y, τ))
    o = QuantileSGD(wgt; τ = τ, start = start)
    update!(o, y)
    o
end

function QuantileSGD(y::Float64,
                     wgt::StochasticWeighting = StochasticWeighting();
                     τ::VecF = [.25, .5, .75],
                     start::VecF = zeros(length(τ)))
    QuantileSGD([y], wgt; τ = τ, start = start)
end

function QuantileSGD(wgt::StochasticWeighting = StochasticWeighting();
                     τ::VecF = [.25, .5, .75],
                     start::VecF = zeros(length(τ)))
   QuantileSGD(start, τ, 0, wgt)
end


#-----------------------------------------------------------------------# state
statenames(o::QuantileSGD) = [:quantiles; :nobs]

state(o::QuantileSGD) = Any[o.q; nobs(o)]


#---------------------------------------------------------------------# update!
function update!(o::QuantileSGD, y::Float64)
    o.n += 1
    γ = weight!(o.weighting)
    for i in 1:length(o.q)
        o.q[i] -= γ * ((y < o.q[i]) - o.τ[i])
    end
    return
end

function updatebatch!(o::QuantileSGD, y::VecF)
    o.n += length(y)
    γ = weight(o, o.w.nb)
    o.q -= γ * (vec(mean(y .< o.q', 1)) - o.τ)
    return
end


