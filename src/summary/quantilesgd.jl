#-------------------------------------------------------# Type and Constructors
type QuantileSGD <: OnlineStat
    est::VecF              # Quantile estimates
    τ::VecF                # tau values (which quantiles)
    n::Int64               # number of observations used
    weighting::StochasticWeighting
end

function QuantileSGD(y::VecF,
                     wgt::StochasticWeighting = StochasticWeighting();
                     τ::VecF = [.25, .5, .75],
                     start::VecF = zeros(length(τ)))
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
statenames(o::QuantileSGD) = [[symbol("τ_($i)") for i in o.τ]; :nobs]

state(o::QuantileSGD) = [o.est, nobs(o)]


#---------------------------------------------------------------------# update!
function update!(o::QuantileSGD, y::Float64)
    o.n += 1
    γ = weight(o)
    o.est -= γ * ((y .< o.est) - o.τ)
    return
end

function updatebatch!(o::QuantileSGD, y::VecF)
    o.n += length(y)
    nextbatch!(o)
    γ = weight(o)
    o.est -= γ * (vec(mean(y .< o.est', 1)) - o.τ)
    return
end


