export FitMvNormal

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type FitMvNormal <: OnlineMultivariateDistribution
    d::Distributions.MvNormal
    c::CovarianceMatrix
    n::Int64
end

onlinefit{T<:Real}(::Type{MvNormal}, y::Matrix{T}) =
    FitMvNormal(fit(MvNormal, y), CovarianceMatrix(y'), size(y, 2))



#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T<:Real}(obj::FitMvNormal, newdata::Matrix{T})
    update!(obj.c, newdata')
    obj.n = nobs(obj.c)
    obj.d = MvNormal(mean(obj.c), cov(obj.c))
end


#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.copy(obj::FitMvNormal) = FitMvNormal(obj.d, obj.c, obj.n)
