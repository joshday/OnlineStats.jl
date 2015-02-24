# Author: Josh Day <emailjoshday@gmail.com>

export OnlineFitDirichlet

# No fit_mle(Dirichlet, obj.stats) method yet

#------------------------------------------------------------------------------#
#-----------------------------------------------------# OnlineFitDirichlet Type
type OnlineFitDirichlet <: ContinuousUnivariateOnlineStat
    d::Distributions.Dirichlet
    stats::Distributions.DirichletStats

    n::Int64
    nb::Int64
end

function onlinefit{T<:Real}(::Type{Dirichlet}, y::Matrix{T})
    n::Int64 = size(y, 2)
    OnlineFitDirichlet(fit(Dirichlet, y), suffstats(Dirichlet, y), n, 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
# function update!(obj::OnlineFitDirichlet, newdata::Vector)
#     newstats = suffstats(Dirichlet, newdata)
#     n1 = obj.stats.tw
#     n2 = newstats.tw
#     n = n1 + n2

#     slogp = obj.stats.slogp + newstats.slogp

#     obj.stats = Distributions.DirichletStats(slogp, n)
#     obj.d = fit_mle(Dirichlet, obj.stats)
#     obj.n = n
#     obj.nb += 1
# end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitDirichlet)
    names = [:α0, [symbol("α$i") for i in 1:length(obj.d.alpha)], :n, :nb]
    estimates = [obj.d.alpha0, obj.d.alpha, obj.n, obj.nb]
    return([names estimates])
end



#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive testing
# x1 = rand(Dirichlet([.2, .3, .5]), 100)
# obj = OnlineStats.onlinefit(Dirichlet, x1)
# OnlineStats.state(obj)

# x2 = rand(Dirichlet([.2, .3, .5]), 100)
# OnlineStats.update!(obj, x2)
# OnlineStats.state(obj)

# obj = OnlineStats.onlinefit(Normal, [x1, x2])
# OnlineStats.state(obj)

