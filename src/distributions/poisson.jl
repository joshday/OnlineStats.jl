#-------------------------------------------------------------# Type and Constructors
type FitPoisson{W <: Weighting} <: DistributionStat
    d::Dist.Poisson
    mean::Mean
    weighting::W
end

function distributionfit{T <: Integer}(::Type{Dist.Poisson}, y::AVec{T}, wgt::Weighting = default(Weighting))
    o = FitPoisson(wgt)
    update!(o, y)
    o
end

FitPoisson(wgt::Weighting = default(Weighting)) = FitPoisson(Dist.Poisson(), Mean(), wgt)


#---------------------------------------------------------------------------# update!
function update!(o::FitPoisson, y::Integer)
    update!(o.mean, Float64(y))
    o.d = Dist.Poisson(mean(o.mean))
end

#---------------------------------------------------------------------------# methods
StatsBase.nobs(o::FitPoisson) = StatsBase.nobs(o.mean)
