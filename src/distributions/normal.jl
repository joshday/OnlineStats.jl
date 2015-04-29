export FitNormal

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type FitNormal <: ScalarStat
    d::Distributions.Normal
    v::Var
    n::Int64
end

function onlinefit{T<:Real}(::Type{Normal}, y::Vector{T})
    n::Int64 = length(y)
    FitNormal(fit(Normal, y), Var(y), n)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T<:Real}(obj::FitNormal, newdata::Vector{T})
    update!(obj.v, newdata)
    obj.n = nobs(obj.v)
    obj.d = Normal(mean(obj.v), sqrt(var(obj.v)))
end
