#-------------------------------------------------------# Type and Constructors
# NOTE: only StochasticWeighting can be used
# NOTE: estimates are: μ = median, σ = (q.75 - q.25) / 2
type FitCauchy <: DistributionStat
    d::Cauchy
    q::QuantileMM
    n::Int64
    weighting::StochasticWeighting
end

function FitCauchy(wgt::StochasticWeighting = StochasticWeighting(); start = zeros(3))
    FitCauchy(Cauchy(), QuantileMM(wgt, start = start), 0, wgt)
end

function FitCauchy(y::AVecF, wgt::StochasticWeighting = StochasticWeighting(); start = zeros(3))
    o = FitCauchy(wgt, start = start)
    update!(o, y)
    o
end

function distributionfit(::Type{Cauchy}, y::AVecF, wgt::StochasticWeighting = StochasticWeighting(); start = zeros(3))
    FitCauchy(y, wgt, start = start)
end



function update!(o::FitCauchy, y::Real)
    update!(o.q, y)
    s = state(o.q)[1]
    o.d = Cauchy(s[2], 0.5 * (s[3] - s[1]))
    o.n += 1
end
