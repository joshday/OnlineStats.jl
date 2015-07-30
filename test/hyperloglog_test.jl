
module HyperLogLogTest

using OnlineStats
using Distributions
using FactCheck

facts("HyperLogLog") do

  # make sure we can't construct
  @fact_throws HyperLogLog(3)
  @fact_throws HyperLogLog(17)

  step = 100
  o = HyperLogLog(10)
  X = [sample(step:step:1000) for i in 1:10000]
  update!(o, X)

  # show(o)
  OnlineStats.DEBUG(o)
  OnlineStats.DEBUG("cardinality should be 10")
  OnlineStats.DEBUG("estimate: $(estimatedCardinality(o))")
  @fact estimatedCardinality(o) --> roughly(10, atol=0.5)

end

end # module