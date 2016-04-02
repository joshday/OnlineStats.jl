abstract Bootstrap{I <: Input} <: OnlineStat{I}
nobs(b::Bootstrap) = b.n
value(b::Bootstrap) = b.replicates

#-----------------------------------------------------------# BernoulliBootstrap
"""
`BernoulliBootstrap(o::OnlineStat, f::Function, r::Int = 1000)`

Create a double-or-nothing bootstrap using `r` replicates of `o` for estimate `f(o)`

Example:
```julia
BernoulliBootstrap(Mean(), mean, 1000)
```
"""
type BernoulliBootstrap{S <: OnlineStat{ScalarInput}} <: Bootstrap{ScalarInput}
    replicates::Vector{S}            # replicates of base stat
    cached_state::Vector{Float64}    # cache of replicate states
    f::Function                      # function to generate state. Ex: mean, var, std
    n::Int                           # number of observations
    cache_is_dirty::Bool
end

function BernoulliBootstrap{T <: ScalarInput}(o::OnlineStat{T}, f::Function, r::Int = 1_000)
    replicates = OnlineStat{T}[copy(o) for i in 1:r]
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
    b
end

#-------------------------------------------------------------# PoissonBootstrap
"""
`PoissonBootstrap(o::OnlineStat, f::Function, r::Int = 1000)`

Create a poisson bootstrap using `r` replicates of `o` for estimate `f(o)`

Example:
```julia
PoissonBootstrap(Mean(), mean, 1000)
```
"""
type ScalarPoissonBootstrap{S <: OnlineStat{ScalarInput}} <: Bootstrap{ScalarInput}
    replicates::Vector{S}           # replicates of base stat
    cached_state::Vector{Float64}  # cache of replicate states
    f::Function
    n::Int                          # number of observations
    cache_is_dirty::Bool
end
function PoissonBootstrap{T <: ScalarInput}(o::OnlineStat{T}, f::Function, r::Int = 1_000)
    replicates = OnlineStat{T}[copy(o) for i in 1:r]
    cached_state = Array(Float64, r)
    ScalarPoissonBootstrap(replicates, cached_state, f, 0, true)
end

type VectorPoissonBootstrap{S <: OnlineStat{VectorInput}} <: Bootstrap{VectorInput}
    replicates::Vector{S}           # replicates of base stat
    cached_state::Matrix{Float64}  # cache of replicate states
    f::Function
    n::Int                          # number of observations
    cache_is_dirty::Bool
end
function PoissonBootstrap{T <: VectorInput}(o::OnlineStat{T}, f::Function, r::Int = 1_000)
    replicates = OnlineStat{T}[copy(o) for i in 1:r]
    cached_state = Array(Float64, length(value(o)), r)
    VectorPoissonBootstrap(replicates, cached_state, f, 0, true)
end

const unitPoissonDist = Ds.Poisson(1)
function fit!(b::Union{ScalarPoissonBootstrap, VectorPoissonBootstrap}, x::Union{Real,Vector})
    b.n += 1
    for replicate in b.replicates
        for repetition in 1:rand(unitPoissonDist)
            fit!(replicate, x)
        end
    end
    b.cache_is_dirty = true
    b
end


#--------------------------------------------------------------# FrozenBootstrap
# "Frozen bootstraps object are generated when two bootstrap distributions are combined
#  e.g., if they are differenced."
immutable FrozenBootstrap <: Bootstrap{ScalarInput}
    cached_state::Vector{Float64}  # cache of replicate states
    n::Int                          # number of observations
end

# "Return the value of interest for each of the `OnlineStat` replicates"
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
function cached_state(b::Bootstrap{ScalarInput})
    if b.cache_is_dirty
        for i in 1:length(b.replicates)
            b.cached_state[i] = b.f(b.replicates[i])
        end
        b.cache_is_dirty = false
    end
    return b.cached_state
end
function cached_state(b::Bootstrap{VectorInput})
    if b.cache_is_dirty
        for i in 1:length(b.replicates)
            b.cached_state[:,i] = b.f(b.replicates[i])
        end
        b.cache_is_dirty = false
    end
    return b.cached_state
end

Base.mean(b::Bootstrap{ScalarInput}) = mean(cached_state(b))
Base.std(b::Bootstrap{ScalarInput}) = std(cached_state(b))
Base.var(b::Bootstrap{ScalarInput}) = var(cached_state(b))

Base.mean(b::Bootstrap{VectorInput}) = vec(mean(cached_state(b),2))
Base.std(b::Bootstrap{VectorInput}) = vec(std(cached_state(b),2))
Base.var(b::Bootstrap{VectorInput}) = vec(var(cached_state(b),2))


replicates(b::Bootstrap) = copy(b.replicates)

# Assumes a and b are independent.
function Base.(:-)(a::Bootstrap{ScalarInput}, b::Bootstrap{ScalarInput})
    return FrozenBootstrap(cached_state(a) - cached_state(b), nobs(a) + nobs(b))
end



function StatsBase.confint(b::Bootstrap{ScalarInput}, coverageprob = 0.95, method=:quantile)
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
