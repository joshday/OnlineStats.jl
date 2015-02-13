# Author: Josh Day <emailjoshday@gmail.com>

export OnlineFitMultinomial

#------------------------------------------------------------------------------#
#--------------------------------------------------------# OnlineNormalFit Type
type OnlineFitMultinomial <: DiscreteMultivariateOnlineStat
    d::Distributions.Multinomial
    stats::Distributions.MultinomialStats

    n::Int64
    nb::Int64
end

function onlinefit(::Type{Multinomial}, x::Matrix)
    n::Int64 = size(x, 2)
    OnlineFitMultinomial(fit(Multinomial, x), suffstats(Multinomial, x), n, 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj1::OnlineFitMultinomial, obj2::OnlineFitMultinomial)
    if obj1.stats.n != obj2.stats.n
        throw(ArgumentError("Number of experiments do not match"))
    end
    n = int(obj1.stats.tw + obj2.stats.tw)
    ne = obj1.stats.n
    scnts = obj1.stats.scnts + obj2.stats.scnts

    obj1.d = Multinomial(ne, scnts / sum(scnts) )
    obj1.stats = Distributions.MultinomialStats(ne, scnts, float(n))
    obj1.n += obj2.n
    obj1.nb += obj2.nb
end

function update!(obj::OnlineFitMultinomial, x::Matrix)
    if obj1.stats.n != sum(x[:, 1])
        throw(ArgumentError("Number of experiments do not match"))
    end
    obj2 = onlinefit(Multinomial, x)
    update!(obj, obj2)
end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitMultinomial)
    println(obj.d)
    println("    n_obs = " * string(obj.n))
    println("n_batches = " * string(obj.nb))
end



#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
# x1 = rand(Multinomial(20, [.2, .3, .5]), 100)
# obj1 = OnlineStats.onlinefit(Multinomial, x1)
# OnlineStats.state(obj1)

# x2 = rand(Multinomial(20, [.2, .3, .5]), 103)
# obj2 = OnlineStats.onlinefit(Multinomial, x2)
# OnlineStats.state(obj2)

# OnlineStats.update!(obj1, obj2)
# OnlineStats.state(obj1)

# x3 = rand(Multinomial(20, [.2, .3, .5]), 103)
# OnlineStats.update!(obj1, x3)
# OnlineStats.state(obj1)

