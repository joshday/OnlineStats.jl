#-------------------------------------------------------# Type and Constructors
type FitLogNormal{W <: Weighting} <: DistributionStat
    d::LogNormal
    v::Variance{W} # track mean and var of log(y)
    n::Int64
    weighting::W
end

function distributionfit(::Type{LogNormal}, y::AVecF, wgt::Weighting = default(Weighting))
    o = FitLogNormal(wgt)
    update!(o, y)
    o
end

FitLogNormal(y::AVecF, wgt::Weighting = default(Weighting)) = distributionfit(LogNormal, y, wgt)

FitLogNormal(wgt::Weighting = default(Weighting)) = FitLogNormal(LogNormal(), Variance(wgt), 0, wgt)


#---------------------------------------------------------------------# update!
function update!(o::FitLogNormal, y::AVecF)
    update!(o.v, log(y))
    o.n = nobs(o.v)
    o.d = LogNormal(mean(o.v), sqrt(var(o.v)))
end
