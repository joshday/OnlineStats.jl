#-------------------------------------------------------# Type and Constructors
type FitMvNormal{W <: Weighting} <: OnlineMultivariateDistribution
    d::Distributions.MvNormal
    c::CovarianceMatrix{W}
    n::Int64
end

function onlinefit{T <: Integer}(::Type{MvNormal},
                                 y::Matrix{T},
                                 wgt::Weighting = default(Weighting))
    o = FitMvNormal(wgt)
    update!(o, y)
    o
end

onlinefit{T<:Real}(::Type{MvNormal}, y::Matrix{T}) =
    FitMvNormal(fit(MvNormal, y), CovarianceMatrix(y'), size(y, 2))


#-----------------------------------------------------------------------# state
statenames(o::FitMvNormal) = [:μ, :Σ, :nobs]

state(o::FitMvNormal) = [o.d.n, o.d.p, o.n]


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T<:Real}(obj::FitMvNormal, newdata::Matrix{T})
    update!(obj.c, newdata')
    obj.n = nobs(obj.c)
    obj.d = MvNormal(mean(obj.c), cov(obj.c))
end
