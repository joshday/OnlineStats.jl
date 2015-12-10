#-------------------------------------------------------# Type and Constructors
type FitNormal{W <: Weighting} <: DistributionStat
    d::Dist.Normal
    v::Variance{W}
    n::Int64
    weighting::W
end

function distributionfit(::Type{Dist.Normal}, y::AVecF, wgt::Weighting = default(Weighting))
    o = FitNormal(wgt)
    update!(o, y)
    o
end

FitNormal(y::AVecF, wgt::Weighting = default(Weighting)) = distributionfit(Dist.Normal, y, wgt)

FitNormal(wgt::Weighting = default(Weighting)) = FitNormal(Dist.Normal(), Variance(wgt), 0, wgt)


#---------------------------------------------------------------------# update!
function update!(o::FitNormal, y::AVecF)
    update!(o.v, y)
    o.n = StatsBase.nobs(o.v)
    o.d = Dist.Normal(mean(o.v), sqrt(var(o.v)))
end
