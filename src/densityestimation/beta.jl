# Author: Josh Day <emailjoshday@gmail.com>

export OnlineFitBeta

#------------------------------------------------------------------------------#
#----------------------------------------------------------# OnlineFitBeta Type
type OnlineFitBeta <: ContinuousUnivariateOnlineStat
    d::Distributions.Beta
    stats::Summary

    n::Int64
    nb::Int64
end

function onlinefit{T<:Real}(::Type{Beta}, y::Vector{T})
    warn("Beta uses MoM instead of MLE")
    n::Int64 = length(y)
    stats = Summary(y)
    m = stats.mean
    v = stats.var
    α = m * (m * (1 - m) / v - 1)
    β = (1 - m) * (m * (1 - m) / v - 1)
    OnlineFitBeta(Beta(α, β), stats, n, 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineFitBeta, newdata::Vector)
    update!(obj.stats, newdata)
    m = obj.stats.mean
    v = obj.stats.var
    α = m * (m * (1 - m) / v - 1)
    β = (1 - m) * (m * (1 - m) / v - 1)
    obj.d = Beta(α, β)
    obj.n += length(newdata)
    obj.nb += 1
end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitBeta)
    names = [:α, :β, :n, :nb]
    estimates = [obj.d.α, obj.d.β, obj.n, obj.nb]
    return([names estimates])
end




#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
# x1 = rand(Beta(3,5), 100000)
# obj = OnlineStats.onlinefit(Beta, x1)
# OnlineStats.state(obj)

# x2 = rand(Beta(3, 5), 10000)
# OnlineStats.update!(obj, x2)
# OnlineStats.state(obj)

