abstract Bootstrap <: OnlineStat
nobs(b::Bootstrap) = b.n

#-----------------------------------------------------------# BernoulliBootstrap
type BernoulliBootstrap{S <: OnlineStat} <: Bootstrap
    replicates::Vector{S}            # replicates of base stat
    cached_state::Vector{Float64}    # cache of replicate states
    f::Function                      # function to generate state. Ex: mean, var, std
    n::Int                           # number of observations
    cache_is_dirty::Bool
end

"""
`BernoulliBootstrap(o, f, r)`

Create a double-or-nothing bootstrap using `r` replicates of OnlineStat `o` for estimate `f(o)`

Example: `BernoulliBootstrap(Mean(), mean, 1000)`
"""
function BernoulliBootstrap(o::OnlineStat, f::Function, r::Int = 1_000)
    replicates = OnlineStat[copy(o) for i in 1:r]
    cached_state = Array(Float64, r)
    return BernoulliBootstrap(replicates, cached_state, f, 0, true)
end

function fit!(b::BernoulliBootstrap, x::Real)
    b.n += 1

    for replicate in b.replicates
        if rand() > 0.5
            fit!(replicate, x)
            fit!(replicate, x)
        end
    end
    b.cache_is_dirty = true
    return
end

#-------------------------------------------------------------# PoissonBootstrap
"""
`PoissonBootstrap(o, f, r)`

Create a poisson bootstrap using `r` replicates of OnlineStat `o` for estimate `f(o)`

Example: `PoissonBootstrap(Mean(), mean, 1000)`
"""
type PoissonBootstrap{S <: OnlineStat} <: Bootstrap
    replicates::Vector{S}           # replicates of base stat
    cached_state::Vector{Float64}  # cache of replicate states
    f::Function
    n::Int                          # number of observations
    cache_is_dirty::Bool
end

function PoissonBootstrap(o::OnlineStat, f::Function, r::Int = 1_000)
    replicates = OnlineStat[copy(o) for i in 1:r]
    cached_state = Array(Float64, r)
    return PoissonBootstrap(replicates, cached_state, f, 0, true)
end

function fit!(b::PoissonBootstrap, x::Real)
    b.n += 1
    for replicate in b.replicates
        repetitions = rand(Ds.Poisson(1))
        for repetition in 1:repetitions
            fit!(replicate, x)
        end
    end
    b.cache_is_dirty = true
    return
end


#--------------------------------------------------------------# FrozenBootstrap
"Frozen bootstrap object are generated when two bootstrap distributions are combined, e.g., if they are differenced."
immutable FrozenBootstrap <: Bootstrap
    cached_state::Vector{Float64}  # cache of replicate states
    n::Int                          # number of observations
end

"return the value of interest for each of the `OnlineStat` replicates"
cached_state(b::FrozenBootstrap) = copy(b.cached_state)

#-----------------------------------------------------------------------# Common
function Base.show(io::IO, b::Bootstrap)
    printheader(io, string(typeof(b)))
    print_item(io, "Boostrap of", typeof(b.replicates[1]))
    print_item(io, "function", b.f)
    print_item(io, "nreplicates", length(b.replicates))
    print_item(io, "nobs", nobs(b))
end

# update cached_state' states if necessary and return their values
function cached_state(b::Bootstrap)
    if b.cache_is_dirty
        for (i, replicate) in enumerate(b.replicates)
            b.cached_state[i] = b.f(replicate)
        end
        b.cache_is_dirty = false
    end
    return b.cached_state
end

Base.mean(b::Bootstrap) = mean(cached_state(b))
Base.std(b::Bootstrap) = std(cached_state(b))
Base.var(b::Bootstrap) = var(cached_state(b))


"Get the replicates of the `OnlineStat` objects used in the bootstrap"
replicates(b::Bootstrap) = copy(b.replicates)

# Assumes a and b are independent.
function Base.(:-)(a::Bootstrap, b::Bootstrap)
    return FrozenBootstrap(cached_state(a) - cached_state(b), nobs(a) + nobs(b))
end



function StatsBase.confint(b::Bootstrap, coverageprob = 0.95, method=:quantile)
    states = cached_state(b)
    # If any NaN, return NaN, NaN
    if any(isnan, states)
        return (NaN, NaN)
    else
        α = 1 - coverageprob
        if method == :quantile
            return (quantile(states, α / 2), quantile(states, 1 - α / 2))
        elseif method == :normal
            norm_approx = Ds.Normal(mean(states), std(states))
            return (quantile(norm_approx, α / 2), quantile(norm_approx, 1 - α / 2))
        else
            error("method $method not recognized.  use :quantile or :normal")
        end
    end
end
