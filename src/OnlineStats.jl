module OnlineStats
using Docile
export OnlineStat

@doc "OnlineStat type.  Keeps track of current estimate and n used" ->
type OnlineStat
  statistic::String
  estimate
  n::Int
end

include("summary.jl")
end # module
