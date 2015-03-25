# Author: Josh Day <emailjoshday@gmail.com>

export OnlineFitBernoulli

#------------------------------------------------------------------------------#
#-----------------------------------------------------# OnlineFitBernoulli Type
type OnlineFitBernoulli <: DiscreteUnivariateOnlineStat
    d::Distributions.Bernoulli
    stats::Distributions.BernoulliStats

    n::Int64
    nb::Int64
end

function onlinefit(::Type{Bernoulli}, y::Vector{Int64})
    n::Int64 = length(y)
    OnlineFitBernoulli(fit(Bernoulli, y), suffstats(Bernoulli, y), n, 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineFitBernoulli, newdata::Vector{Int64})
    newstats = suffstats(Bernoulli, newdata)

    cnt0 = obj.stats.cnt0 + newstats.cnt0
    cnt1 = obj.stats.cnt1 + newstats.cnt1

    obj.n = cnt0 + cnt1
    obj.d = Bernoulli(cnt1 / obj.n)
    obj.stats = Distributions.BernoulliStats(cnt0, cnt1)
    obj.nb += 1
end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitBernoulli)
    names = [:p, :n, :nb]
    estimates = [obj.d.p, obj.n, obj.nb]
    return([names estimates])
end




#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
# x1 = rand(Bernoulli(.7), 100)
# obj = OnlineStats.onlinefit(Bernoulli, x1)
# OnlineStats.state(obj)

# x2 = rand(Bernoulli(.7), 100)
# OnlineStats.update!(obj, x2)
# OnlineStats.state(obj)

