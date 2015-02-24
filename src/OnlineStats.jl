module OnlineStats

using DataFrames
using Docile
using Distributions
using StatsBase
import PDMats
import Gadfly

export update!, state, onlinefit, n_obs, n_batches, make_df, make_df!


# General functions
@doc doc"Return the number of observations used" ->
function n_obs(obj)
   obj.n
end

@doc doc"Return the number of batches used" ->
function n_batches(obj)
   obj.nb
end

function make_df(obj)
    s = OnlineStats.state(obj)
    names::Vector{Symbol} = s[:, 1]
    df = convert(DataFrame, s[:, 2]')
    names!(df, names)
    return df
end

function make_df!(obj, df::DataFrame)
    push!(df, state(obj)[:, 2])
end

# Abstract Type structure
include("onlinestat.jl")

# Summary Statistics
include("summary/covmatrix.jl")
include("summary/moments.jl")
include("summary/summary.jl")
include("summary/quantile.jl")
include("summary/fivenumber.jl")

# Density Estimation
include("densityestimation/bernoulli.jl")
include("densityestimation/beta.jl")
include("densityestimation/binomial.jl")
# include("densityestimation/dirichlet.jl")
include("densityestimation/exponential.jl")
include("densityestimation/gamma.jl")
include("densityestimation/multinomial.jl")
include("densityestimation/mvnormal.jl")
include("densityestimation/normal.jl")

# Linear Model
include("linearmodel/sweep.jl")
include("linearmodel/lm.jl")

# Quantile Regression
include("quantileregression/quantregsgd.jl")






# General docs for update!, state, convert, onlinefit
@doc doc"""
    Update `obj::OnlineStat` with observations in `newdata` using `update(obj, newdata)`
    """ -> update!

@doc doc"""
    Get current state of estimates with `state(obj::OnlineStat)`
    """ -> state


@doc doc"""
    Usage:
    ```
    onlinefit(<<UnivariateDistribution>>, y::Vector)
    onlinefit(<<MultivariateDistribution>>, y::Matrix)
    ```

    Online parametric density estimation.  Creates an object of type
    `OnlineFit<<Distribution>>`

    | Field                          |  Description                          |
    |:-------------------------------|:--------------------------------------|
    | `d::<<Distribution>>`          | `Distributions.<<Distribution>>`      |
    | `stats::<<DistributionStats>>` | `Distributions.<<DistributionStats>>` |
    | `n::Int64`                     | number of observations used           |
    | `nb::Int64`                    | number of batches used                |


    Examples:
    ```
    y1, y2 = randn(100), randn(100)
    obj = onlinefit(Normal, y1)
    update!(obj, y2)
    state(obj)
    ```

    """ -> onlinefit

end # module
