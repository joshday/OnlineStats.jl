module OnlineStats

import DataFrames
import DataArrays
import Distributions

using Docile

export update!, state, convert

include("summary/summary.jl")
include("summary/quantile.jl")

# General Docs
@doc """
  Usage: `state(obj)`

View the current state of estimates in `obj`
""" -> state

end # module
