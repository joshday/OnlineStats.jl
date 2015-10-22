#-------------------------------------------------------------# Type and Constructors
type FitPoisson{W <: Weighting} <: DistributionStat
    d::Poisson
    mean::Mean
    weighting::W
end

function distributionfit{T <: Integer}(::Type{Poisson}, y::AVec{T}, wgt::Weighting = default(Weighting))
    o = FitPoisson(wgt)
    update!(o, y)
    o
end

FitPoisson(wgt::Weighting = default(Weighting)) = FitPoisson(Poisson(), Mean(), wgt)


#---------------------------------------------------------------------------# update!
function update!(o::FitPoisson, y::Integer)
    update!(o.mean, Float64(y))
    o.d = Poisson(mean(o.mean))
end

#---------------------------------------------------------------------------# methods
nobs(o::FitPoisson) = nobs(o.mean)
