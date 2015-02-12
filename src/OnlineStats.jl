module OnlineStats

using DataFrames
using Docile
using Distributions
import Base.merge

export update!, state, onlinefit, n_obs, n_used


# Abstract Type structure
include("onlinestat.jl")

# Summary Statistics
include("summary/summary.jl")
include("summary/quantile.jl")
include("summary/moments.jl")

# Density Estimation
include("densityestimation/normal.jl")
include("densityestimation/binomial.jl")
include("densityestimation/bernoulli.jl")


# General functions
function n_obs(obj)
   obj.n
end

function n_batches(obj)
   obj.nb
end


# General docs for update!, state, convert
@doc doc"""
  `update!(obj, newdata::Vector, add::Bool=true)`

Update object `obj` with observations in `newdata`.  Overwrite previous
estimates (`add = false`) or append new estimates (`add = true`)
""" -> update!

@doc doc"""
  `state(obj)`

Get current state of estimates in `obj`
""" -> state

@doc doc"""
  `convert(DataFrame, obj)`

Get `obj` results as `DataFrame`
""" -> convert

end # module
