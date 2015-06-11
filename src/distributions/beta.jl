#------------------------------------------------------# Type and Constructors
type FitBeta{W <: Weighting} <: DistributionStat
    d::Beta
    stats::Variance{W}
    n::Int64
    weighting::W
end

function onlinefit(::Type{Beta}, y::VecF, wgt::Weighting = default(Weighting))
    warn("FitBeta Uses method of moments, not MLE")
    o = FitBeta(wgt)
    update!(o, y)
    o
end

FitBeta{T <: Real}(y::Vector{T}, wgt::Weighting = default(Weighting)) =
    onlinefit(Beta, y, wgt)

FitBeta(wgt::Weighting = default(Weighting)) =
    FitBeta(Beta(), Variance(wgt), 0, wgt)


#---------------------------------------------------------------------# update!
function update!(obj::FitBeta, y::Float64)
    update!(obj.stats, y)  # Weighting is applied to updating Variance
    m = mean(obj.stats)
    v = var(obj.stats)
    α = m * (m * (1 - m) / v - 1)
    β = (1 - m) * (m * (1 - m) / v - 1)

    if α <= 0
        α = .01
    end
    if β <= 0
        β = .01
    end

    obj.d = Beta(α, β)
    obj.n += 1
end
