# Author: Josh Day <emailjoshday@gmail.com>

export OnlineFitGamma

#------------------------------------------------------------------------------#
#---------------------------------------------------------# OnlineFitGamma Type
type OnlineFitGamma <: ContinuousUnivariateOnlineStat
    d::Distributions.Gamma
    stats::Distributions.GammaStats

    n::Int64
    nb::Int64
end

function onlinefit{T<:Real}(::Type{Gamma}, y::Vector{T})
    n::Int64 = length(y)
    OnlineFitGamma(fit(Gamma, y), suffstats(Gamma, y), n, 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineFitGamma, newdata::Vector)
    newstats = suffstats(Gamma, newdata)
    n1 = obj.stats.tw
    n2 = newstats.tw
    n = n1 + n2

    sx = obj.stats.sx + newstats.sx
    slogx = obj.stats.slogx + newstats.slogx
    tw = n

    obj.stats = Distributions.GammaStats(sx, slogx, n)
    obj.d = fit_mle(Gamma, obj.stats)
    obj.n = n
    obj.nb += 1
end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitGamma)
    println(obj.d)
end

