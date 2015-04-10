export OnlineFitMvNormal

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type OnlineFitMvNormal <: ContinuousUnivariateOnlineStat
    d::Distributions.MvNormal
    c::CovarianceMatrix
    n::Int64
    nb::Int64
end

onlinefit{T<:Real}(::Type{MvNormal}, y::Matrix{T}) =
    OnlineFitMvNormal(fit(MvNormal, y), CovarianceMatrix(y'), size(y, 2), 1)



#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T<:Real}(obj::OnlineFitMvNormal, newdata::Matrix{T})
    update!(obj.c, newdata')
    obj.n = nobs(obj.c)
    obj.d = MvNormal(mean(obj.c), cov(obj.c))
    obj.nb += 1
end



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitMvNormal)
    names = [[symbol("μ$i") for i=1:length(obj.d.μ)];
             [symbol("σ$i") for i=1:length(obj.d.μ)];
             :n; :nb]
    estimates = [obj.d.μ; sqrt(diag(obj.d.Σ)); obj.n; obj.nb]
    return([names estimates])
end

vcov(obj::OnlineFitMvNormal) = obj.d.Σ.mat



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.copy(obj::OnlineFitMvNormal) =
    OnlineFitMvNormal(obj.d, obj.c, obj.n, obj.nb)

function Base.show(io::IO, obj::OnlineFitMvNormal)
    @printf(io, "OnlineFit (nobs = %i)\n", obj.n)
    show(obj.d)
end
