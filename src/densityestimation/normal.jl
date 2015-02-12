# Author: Josh Day <emailjoshday@gmail.com>

export OnlineFitNormal

#------------------------------------------------------------------------------#
#--------------------------------------------------------# OnlineNormalFit Type
type OnlineFitNormal <: ContinuousUnivariateOnlineStat
    d::Distributions.Normal
    stats::Distributions.NormalStats

    n::Int64
    nb::Int64
end


function onlinefit{T<:Real}(::Type{Normal}, y::Vector{T})
    n::Int64 = length(y)
    OnlineFitNormal(fit(Normal, y), suffstats(Normal, y), n, 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineFitNormal, newdata::Vector)
    newstats = suffstats(Normal, newdata)
    n1 = obj.stats.tw
    n2 = newstats.tw
    n = n1 + n2

    s = obj.stats.s + newstats.s
    m = obj.stats.m + n1 / n * (newstats.m - obj.stats.m)
    s2 = obj.stats.s2 + newstats.s2
    tw = n

    obj.d = Normal(m, s2 / n)
    obj.stats = Distributions.NormalStats(s, m, s2, tw)
    obj.n = n
    obj.nb += 1
end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(OnlineFitNormal)
    println(obj.d)
end
