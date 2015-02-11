module OnlineStats


using DataFrames
using Docile

import Distributions, Base.convert

export update!, state, convert

include("onlinestat.jl")
include("summary/summary.jl")
include("summary/quantile.jl")


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
