export OnlineFitExponential

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type OnlineFitExponential <: ContinuousUnivariateOnlineStat
    d::Distributions.Exponential
    m::Mean
    n::Int64
    nb::Int64
end

onlinefit{T<:Real}(::Type{Exponential}, y::Vector{T}) =
    OnlineFitExponential(fit(Exponential, y), Mean(y), length(y), 1)



#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T<:Real}(obj::OnlineFitExponential, newdata::Vector{T})
    update!(obj.m, newdata)
    obj.n = nobs(obj.m)
    obj.d = Exponential(mean(obj.m))
    obj.nb += 1
end



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitExponential)
    names = [:β, :n, :nb]
    estimates = [obj.d.β, obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.copy(obj::OnlineFitExponential) =
    OnlineFitExponential(obj.d, obj.m, obj.n, obj.nb)

function Base.show(io::IO, obj::OnlineFitExponential)
    @printf(io, "OnlineFit (nobs = %i)\n", obj.n)
    show(obj.d)
end

