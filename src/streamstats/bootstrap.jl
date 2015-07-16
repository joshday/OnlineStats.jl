abstract Bootstrap <: OnlineStat

#-----------------------------------------------------------# BernoulliBootstrap
## Double-or-nothing online bootstrap
type BernoulliBootstrap{S <: OnlineStat} <: Bootstrap
    replicates::Vector{S}            # replicates of base stat
    cached_state::Vector{Float64}    # cache of replicate states
    n::Int                           # number of observations
    cache_is_dirty::Bool
end

function BernoulliBootstrap{S <: OnlineStat}(stat::S, R::Int = 1_000, α::Real = 0.05)
    replicates = S[copy(stat) for i in 1:R]
    cached_state = Array(Float64, R)
    return BernoulliBootstrap(replicates, cached_state, 0, true)
end

function update!(stat::BernoulliBootstrap, args...)
    stat.n += 1

    for replicate in stat.replicates
        if rand() > 0.5
            update!(replicate, args...)
            update!(replicate, args...)
        end
    end
    stat.cache_is_dirty = true
    return
end

#-----------------------------------------------------------------------# Common
# update cached_state' states if necessary and return their values
function cached_state(b::Bootstrap)
    if b.cache_is_dirty
        for (i, replicate) in enumerate(b.replicates)
            b.cached_state[i] = state(replicate)[1]  # assumes the statistic of interest is state(o)[1]
        end
        b.cache_is_dirty = false
    end
    return b.cached_state
end

mean(b::Bootstrap) = mean(cached_state(b))
std(b::Bootstrap) = std(cached_state(b))
var(b::Bootstrap) = var(cached_state(b))

state(b::Bootstrap) = [length(b.replicates), nobs(b)]
statenames(b::Bootstrap) = [:replicates, :nobs]

replicates(b::Bootstrap) = copy(b.replicates)


function confint(b::Bootstrap, coverageprob = 0.95, method=:quantile)
    states = cached_state(b)
    # If any NaN, return NaN, NaN
    if any(isnan, states)
        return (NaN, NaN)
    else
        α = 1 - coverageprob
        if method == :quantile
            return (quantile(states, α / 2), quantile(states, 1 - α / 2))
        elseif method == :normal
            norm_approx = Normal(mean(states), std(states))
            return (quantile(norm_approx, α / 2), quantile(norm_approx, 1 - α / 2))
        else
            error("method $method not recognized.  use :quantile or :normal")
        end
    end
end



## TESTING
if true
    o = OnlineStats.Mean()
    o = OnlineStats.BernoulliBootstrap(o, 1000, .05)
    OnlineStats.update!(o, rand(10000))
    OnlineStats.cached_state(o)
    mean(o)
    std(o)
    var(o)
    confint(o)
end
