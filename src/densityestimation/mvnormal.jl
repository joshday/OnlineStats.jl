# Author: Josh Day <emailjoshday@gmail.com>

export OnlineFitMvNormal

#------------------------------------------------------------------------------#
#--------------------------------------------------------# OnlineNormalFit Type
type OnlineFitMvNormal <: ContinuousUnivariateOnlineStat
    d::Distributions.MvNormal
    stats::Distributions.MvNormalStats

    n::Int64
    nb::Int64
end

function onlinefit{T<:Real}(::Type{MvNormal}, y::Matrix{T})
    n::Int64 = size(y, 2)
    OnlineFitMvNormal(fit(MvNormal, y), suffstats(MvNormal, y), n, 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineFitMvNormal, newdata::Matrix)
    newstats = suffstats(MvNormal, newdata)
    n1 = obj.stats.tw
    n2 = newstats.tw
    n = n1 + n2

    s = obj.stats.s + newstats.s
    m = obj.stats.m + n2 / n * (newstats.m - obj.stats.m)

    A1 = obj.d.Σ.mat * (n1 / (n1 - 1)) + (n1 / (n1-1)) * obj.d.μ * obj.d.μ'
    A2 = newstats.s2 / (n2 - 1) + (n2 / (n2 - 1)) * newstats.m * newstats.m'
    A = ((n1 - 1) * A1 + (n2 - 2) * A2) / (n - 1)
    s2 = A - n / (n-1) * m * m'
    tw = n

    obj.d = MvNormal(m, s2)
    obj.stats = Distributions.MvNormalStats(s, m, s2, tw)
    obj.n = n
    obj.nb = obj.nb + 1
end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitMvNormal)
    println(obj.d)
end



x1 = randn(3, 100)
obj = OnlineStats.onlinefit(MvNormal, x1)
OnlineStats.state(obj)

x2 = randn(3, 100)
OnlineStats.update!(obj, x2)
OnlineStats.state(obj)


obj = OnlineStats.onlinefit(MvNormal, [x1 x2])
OnlineStats.state(obj)

