abstract Bootstrap <: OnlineStat

#-----------------------------------------------------------# BernoulliBootstrap
## Double-or-nothing online bootstrap
type BernoulliBootstrap{S <: OnlineStat} <: Bootstrap
    replicates::Vector{S}            # replicates of base stat
    cached_state::Vector{Float64}    # cache of replicate states
    n::Int                           # number of observations
    cache_is_dirty::Bool
end

function BernoulliBootstrap{S <: OnlineStat}(stat::S, R::Int = 1_000)
    replicates = S[copy(stat) for i in 1:R]
    cached_state = Array(Float64, R)
    return BernoulliBootstrap(replicates, cached_state, 0, true)
end

function update!(b::BernoulliBootstrap, args...)
    b.n += 1

    for replicate in b.replicates
        if rand() > 0.5
            update!(replicate, args...)
            update!(replicate, args...)
        end
    end
    b.cache_is_dirty = true
    return
end

#-------------------------------------------------------------# PoissonBootstrap
type PoissonBootstrap{S <: OnlineStat} <: Bootstrap
    replicates::Vector{S}           # replicates of base stat
    cached_state::Vector{Float64}  # cache of replicate states
    n::Int                          # number of observations
    cache_is_dirty::Bool
end

function PoissonBootstrap{S <: OnlineStat}(stat::S, R::Int = 1_000)
    replicates = S[copy(stat) for i in 1:R]
    cached_state = Array(Float64, R)
    return PoissonBootstrap(replicates, cached_state, 0, true)
end

function update!(b::PoissonBootstrap, args::Any...)
    b.n += 1
    for replicate in b.replicates
        repetitions = rand(Poisson(1))
        for repetition in 1:repetitions
            update!(replicate, args...)
        end
    end
    b.cache_is_dirty = true
    return
end


#--------------------------------------------------------------# FrozenBootstrap
# Frozen bootstrap object are generated when two bootstrap distributions
# are combined, e.g., if they are differenced.
immutable FrozenBootstrap <: Bootstrap
    cached_state::Vector{Float64}  # cache of replicate states
    n::Int                          # number of observations
end

cached_state(b::FrozenBootstrap) = copy(b.cached_state)

#-----------------------------------------------------------------------# Common
function show(io::IO, b::Bootstrap)
    println(io, typeof(b))
    println(io, "Online Bootstrap of ", typeof(b.replicates[1]))
    println(io, "*  nreplicates = ", length(b.replicates))
    println(io, "*         nobs = ", nobs(b))
end

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

# Assumes a and b are independent.
function Base.(:-)(a::Bootstrap, b::Bootstrap)
    return FrozenBootstrap(
        cached_state(a) - cached_state(b),
        nobs(a) + nobs(b)
    )
end



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
if false
    o = OnlineStats.Mean()
    o = OnlineStats.BernoulliBootstrap(o, 1000)
    OnlineStats.update!(o, rand(10000))
    OnlineStats.cached_state(o)
    mean(o)
    std(o)
    var(o)
    confint(o)

    o2 = OnlineStats.Mean()
    o2 = OnlineStats.PoissonBootstrap(o2, 1000)
    OnlineStats.update!(o2, rand(10000))
    OnlineStats.cached_state(o2)
    mean(o2)
    std(o2)
    var(o2)
    confint(o2)

    @fact typeof(o1 - o2) => OnlineStats.FrozenBootstrap
end
