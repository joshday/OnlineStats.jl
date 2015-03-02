module OnlineStats

using Docile
using DataFrames, Distributions, StatsBase
import PDMats, Distributions
import Base: copy, merge, merge!, show, quantile

export update!, state, onlinefit, n_obs, n_batches, make_df, make_df!

# Abstract Type structure
include("types.jl")


###############################################################################
#
# Functions for any OnlineStat type
#
###############################################################################
@doc doc"Return the number of observations used" ->
function n_obs{T <: OnlineStat}(obj::T)
   obj.n
end

@doc doc"Return the number of batches used" ->
function n_batches{T <: OnlineStat}(obj::T)
   obj.nb
end

@doc doc"Put object results in a DataFrame" ->
function make_df{T <: OnlineStat}(obj::T)
    s = OnlineStats.state(obj)
    names::Vector{Symbol} = s[:, 1]
    df = convert(DataFrame, s[:, 2]')
    names!(df, names)
    return df
end

@doc doc"Add the current state of `obj` to a new row in `df`" ->
function make_df!{T <: OnlineStat}(obj::T, df::DataFrame)
    push!(df, state(obj)[:, 2])
end



###############################################################################
#
# OnlineStat Types
#
# Each file has the type definition and methods for update!() and state()
#
###############################################################################
# Summary Statistics
include("summary/mean.jl")
include("summary/var.jl")
include("summary/extrema.jl")
include("summary/summary.jl")
include("summary/covmatrix.jl")
include("summary/moments.jl")
include("summary/quantilesgd.jl")
include("summary/quantilemm.jl")
include("summary/fivenumber.jl")

# # Density Estimation
# include("densityestimation/bernoulli.jl")
# include("densityestimation/beta.jl")
# include("densityestimation/binomial.jl")
# # include("densityestimation/dirichlet.jl")
# include("densityestimation/exponential.jl")
# include("densityestimation/gamma.jl")
# include("densityestimation/multinomial.jl")
# include("densityestimation/mvnormal.jl")
# include("densityestimation/normal.jl")

# # Linear Model
# include("linearmodel/sweep.jl")
# include("linearmodel/lm.jl")

# # Quantile Regression
# include("quantileregression/quantregsgd.jl")
# include("quantileregression/quantregmm.jl")





###############################################################################
#
# API docs for udpate!, state, convert, and onlinefit
#
###############################################################################
# General docs for update!, state, convert, onlinefit
# @doc doc"""
#     Update `obj::OnlineStat` with observations in `newdata` using `update(obj, newdata)`
#     """ -> update!

# @doc doc"""
#     Get current state of estimates with `state(obj::OnlineStat)`
#     """ -> state


# @doc doc"""
#     Usage:
#     ```
#     onlinefit(<<UnivariateDistribution>>, y::Vector)
#     onlinefit(<<MultivariateDistribution>>, y::Matrix)
#     ```

#     Online parametric density estimation.  Creates an object of type
#     `OnlineFit<<Distribution>>`

#     | Field                          |  Description                          |
#     |:-------------------------------|:--------------------------------------|
#     | `d::<<Distribution>>`          | `Distributions.<<Distribution>>`      |
#     | `stats::<<DistributionStats>>` | `Distributions.<<DistributionStats>>` |
#     | `n::Int64`                     | number of observations used           |
#     | `nb::Int64`                    | number of batches used                |


#     Examples:
#     ```
#     y1, y2 = randn(100), randn(100)
#     obj = onlinefit(Normal, y1)
#     update!(obj, y2)
#     state(obj)
#     ```

#     """ -> onlinefit

end # module
