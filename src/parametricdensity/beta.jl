export OnlineFitBeta

#----------------------------------------------------------------------------#
#------------------------------------------------------# Type and Constructors
type OnlineFitBeta <: ContinuousUnivariateOnlineStat
    d::Distributions.Beta
    stats::Summary
    n::Int64
    nb::Int64
end

function onlinefit{T<:Real}(::Type{Beta}, y::Vector{T})
    n::Int64 = length(y)
    stats = Summary(y)
    m = mean(stats)
    v = var(stats)
    α = m * (m * (1 - m) / v - 1)
    β = (1 - m) * (m * (1 - m) / v - 1)
    OnlineFitBeta(Beta(α, β), stats, n, 1)
end



#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T<:Real}(obj::OnlineFitBeta, newdata::Vector{T})
    update!(obj.stats, newdata)
    m = mean(obj.stats)
    v = var(obj.stats)
    α = m * (m * (1 - m) / v - 1)
    β = (1 - m) * (m * (1 - m) / v - 1)
    obj.d = Beta(α, β)
    obj.n += length(newdata)
    obj.nb += 1
end



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitBeta)
    names = [:α, :β, :n, :nb]
    estimates = [obj.d.α, obj.d.β, obj.n, obj.nb]
    return([names estimates])
end



#----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# Base
Base.copy(obj::OnlineFitBeta) = OnlineFitBeta(obj.d, obj.stats, obj.n, obj.nb)

function Base.show(io::IO, obj::OnlineFitBeta)
    @printf(io, "OnlineFitBeta (nobs = %i)\n", obj.n)
    show(obj.d)
end

