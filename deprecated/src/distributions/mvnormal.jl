#-------------------------------------------------------# Type and Constructors
type FitMvNormal{W <: Weighting} <: DistributionStat
    d::Dist.MvNormal
    c::CovarianceMatrix{W}
    n::Int64
    weighting::W
end

function distributionfit(::Type{Dist.MvNormal}, y::AMatF, wgt::Weighting = default(Weighting))
    o = FitMvNormal(ncols(y), wgt)
    updatebatch!(o, y)
    o
end

FitMvNormal(y::AMatF, wgt::Weighting = default(Weighting)) =
    distributionfit(Dist.MvNormal, y, wgt)

FitMvNormal(p::Int, wgt::Weighting = default(Weighting)) =
    FitMvNormal(Dist.MvNormal(zeros(p), eye(p)), CovarianceMatrix(p, wgt), 0, wgt)


#---------------------------------------------------------------------# update!
function updatebatch!(o::FitMvNormal, y::AMatF)
    updatebatch!(o.c, y)
    o.n = StatsBase.nobs(o.c)
    o.d = Dist.MvNormal(mean(o.c), cov(o.c))
end

update!(o::FitMvNormal, y::AVecF) = updatebatch!(o, y')
