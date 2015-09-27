#-------------------------------------------------------# Type and Constructors
# NOTE: only LearningRate can be used (based on quantiles)
# NOTE: estimates are: μ = median, σ = (q.75 - q.25) / 2
type FitCauchy <: DistributionStat
    d::Cauchy
    q::QuantileMM
    n::Int64
    weighting::LearningRate
end

function FitCauchy(wgt::LearningRate = LearningRate(r = .6); start = zeros(3))
    FitCauchy(Cauchy(), QuantileMM(wgt, start = start), 0, wgt)
end

function FitCauchy(y::AVecF, wgt::LearningRate = LearningRate(r = .6); start = zeros(3))
    o = FitCauchy(wgt, start = start)
    update!(o, y)
    o
end

function distributionfit(::Type{Cauchy}, y::AVecF, wgt::LearningRate = LearningRate(r = .6); start = zeros(3))
    FitCauchy(y, wgt, start = start)
end



function update!(o::FitCauchy, y::Real)
    update!(o.q, y)
    s = state(o.q)[1]
    o.d = Cauchy(s[2], max(0.5 * (s[3] - s[1]), 1e-10))
    o.n += 1
end
