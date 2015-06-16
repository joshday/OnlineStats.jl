#-------------------------------------------------------# Type and Constructors
type FitNormal{W <: Weighting} <: DistributionStat
    d::Normal
    v::Variance{W}
    n::Int64
    weighting::W
end

function onlinefit(::Type{Normal}, y::VecF, wgt::Weighting = default(Weighting))
    o = FitNormal(wgt)
    update!(o, y)
    o
end

FitNormal(y::VecF, wgt::Weighting = default(Weighting)) = onlinefit(Normal, y, wgt)

FitNormal(wgt::Weighting = default(Weighting)) = FitNormal(Normal(), Variance(wgt), 0, wgt)


#---------------------------------------------------------------------# update!
function update!(o::FitNormal, y::VecF)
    update!(o.v, newdata)
    o.n = nobs(o.v)
    o.d = Normal(mean(o.v), sqrt(var(o.v)))
end
