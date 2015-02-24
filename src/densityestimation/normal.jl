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
    δ = newstats.m - obj.stats.m

    s = obj.stats.s + newstats.s
    m = obj.stats.m + (n2 / n) * δ
    s2 = obj.stats.s2 + newstats.s2 + (n1 * n2 / n) * δ^2

    obj.d = Normal(m, s2 / n)
    obj.stats = Distributions.NormalStats(s, m, s2, n)
    obj.n = n
    obj.nb += 1
end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitNormal)
    names = [:μ, :σ, :n, :nb]
    estimates = [obj.d.μ, obj.d.σ, obj.n, obj.nb]
    return([names estimates])
end



#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive testing
# x1 = randn(3100)
# mean(x1), var(x1)
# obj = OnlineStats.onlinefit(Normal, x1)
# OnlineStats.state(obj)

# x2 = randn(10000)
# mean([x1, x2]), var([x1, x2])
# OnlineStats.update!(obj, x2)
# OnlineStats.state(obj)

# obj = OnlineStats.onlinefit(Normal, [x1, x2])
# OnlineStats.state(obj)

