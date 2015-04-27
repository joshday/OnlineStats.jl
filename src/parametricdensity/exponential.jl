export FitExponential

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type FitExponential <: OnlineUnivariateDistribution
    d::Distributions.Exponential
    m::Mean
    n::Int64
end

onlinefit{T<:Real}(::Type{Exponential}, y::Vector{T}) =
    FitExponential(fit(Exponential, y), Mean(y), length(y))


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T<:Real}(obj::FitExponential, newdata::Vector{T})
    update!(obj.m, newdata)
    obj.n = nobs(obj.m)
    obj.d = Exponential(mean(obj.m))
end


#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.copy(obj::FitExponential) =
    FitExponential(obj.d, obj.m, obj.n)
