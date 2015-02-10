module OnlineStats


using Docile
using DataFrames
using Distributions

export update!, state, convert

include("summary/summary.jl")
include("summary/quantile.jl")

# General Doc for state()
@doc """
  Usage: `state(obj)`

View the current state of estimates in `obj`
""" -> state

end # module
