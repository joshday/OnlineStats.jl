#------------------------------------------------------# Type and Constructors
type FitBeta{W <: Weighting} <: ScalarStat
    d::Beta
    stats::Var{W}
    n::Int64
    weighting::W
end

function onlinefit{T <: Real}(::Type{Beta},
                              y::Vector{T},
                              wgt::Weighting = default(Weighting))
    warn("FitBeta Uses method of moments, not MLE")
    o = FitBeta(wgt)
    update!(o, y)
    o
end

FitBeta{T <: Real}(y::Vector{T}, wgt::Weighting = default(Weighting)) =
    onlinefit(Beta, y, wgt)

FitBeta(wgt::Weighting = default(Weighting)) =
    FitBeta(Beta(), Var(wgt), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::FitBeta) = [:α, :β, :nobs]

state(o::FitBeta) = [o.d.α, o.d.β, o.n]


#---------------------------------------------------------------------# update!
function update!(obj::FitBeta, y::Float64)
    update!(obj.stats, y)  # Weighting is applied to updating Var
    m = mean(obj.stats)
    v = var(obj.stats)
    α = m * (m * (1 - m) / v - 1)
    β = (1 - m) * (m * (1 - m) / v - 1)
    obj.d = Beta(α, β)
    obj.n += 1
end
