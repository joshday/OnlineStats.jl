export OnlineFitNormal

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type OnlineFitNormal <: ContinuousUnivariateOnlineStat
    d::Distributions.Normal
    v::Var
    n::Int64
    nb::Int64
end

function onlinefit{T<:Real}(::Type{Normal}, y::Vector{T})
    n::Int64 = length(y)
    OnlineFitNormal(fit(Normal, y), Var(y), n, 1)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T<:Real}(obj::OnlineFitNormal, newdata::Vector{T})
    update!(obj.v, newdata)
    obj.n = nobs(obj.v)
    obj.d = Normal(mean(obj.v), sqrt(var(obj.v)))
    obj.nb += 1
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitNormal)
    names = [:μ, :σ, :n, :nb]
    estimates = [obj.d.μ, obj.d.σ, obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.copy(obj::OnlineFitNormal) =
    OnlineFitNormal(obj.d, obj.v, obj.n, obj.nb)

function Base.show(io::IO, obj::OnlineFitNormal)
    @printf(io, "OnlineFit (nobs = %i)\n", obj.n)
    show(obj.d)
end

