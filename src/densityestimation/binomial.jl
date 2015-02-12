# Author: Josh Day <emailjoshday@gmail.com>

export OnlineFitBinomial

#------------------------------------------------------------------------------#
#--------------------------------------------------------# OnlineNormalFit Type
type OnlineFitBinomial <: DiscreteUnivariateOnlineStat
    d::Distributions.Binomial
    stats::Distributions.BinomialStats

    n::Int64
    nb::Int64
end

function onlinefit(::Type{Binomial}, ne::Int64, y::Vector{Int64})
    n::Int64 = length(y)
    OnlineFitBinomial(fit(Binomial, ne, y), suffstats(Binomial, ne, y), n, 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineFitBinomial, newdata::Vector)
    newstats = suffstats(Binomial, obj.stats.n, newdata)

    ns = obj.stats.ns + newstats.ns
    ne = obj.stats.ne + newstats.ne

    obj.d = Binomial(obj.stats.n, ns / (ne*obj.n))
    obj.stats = Distributions.BinomialStats(ns, ne, obj.stats.n)
    obj.n = ne
    obj.nb += 1
end

#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitBinomial)
    println(obj.d)
    println("nobs = " * string(obj.n))
    println("  nb = " * string(obj.nb))
end



x1 = rand(Binomial(10, .2), 100)
obj = OnlineStats.onlinefit(Binomial, 10, x1)
OnlineStats.state(obj)

x2 = rand(Binomial(10, .2), 100)
OnlineStats.update!(obj, x2)
OnlineStats.state(obj)
