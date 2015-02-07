# This script includes implementations of online summary statistics
# Each statistic has a function of form:
#
# oStatistic, which returns type OnlineStat{SummaryStatistic}
#
#
# Also implmented is the summaryTrace function, which returns the trace results
# for
#
# Author: Josh Day <emailjoshday@gmail.com>


#------------------------------------------------------------------------------#
#                                                                      Exports #
#------------------------------------------------------------------------------#
export SummaryStatistic, OnlineStat
export oMean, oVar, oQuantile
export update!, summaryTrace


#------------------------------------------------------------------------------#
#                                                                        Types #
#------------------------------------------------------------------------------#
type SummaryStatistic
end

type OnlineStat{SummaryStatistic}
  notes::String
  details::DataFrame
end


#------------------------------------------------------------------------------#
#                                                        First Batch Functions #
#------------------------------------------------------------------------------#
function oMean(y::Vector)
  OnlineStat{SummaryStatistic}("mean",
                               DataFrame(mean=mean(y),
                                         n = length(y),
                                         nBatch = 1))
end

# function oVar(y::Vector)
#   OnlineStat{SummaryStatistic}("var, mean", (var(y), mean(y)), length(y), 1)
# end

# function oQuantile(y::Vector, tau::Float64, r::Float64 = .51, alg::String="S")
#   if r <= .5 || r > 1
#     warn("learning rate r must be in (.5, 1]")
#   end

#   if alg == "S"  # Stochastic Subgradient Descent
#     OnlineStat{SummaryStatistic}("quantile-S", (quantile(y, tau), tau, r),
#                                  length(y), 1)
#   else alg == "MM"  # MM Algorithm
#     OnlineStat{SummaryStatistic}("quantile-MM", (quantile(y, tau), tau, r),
#                                  length(y), 1)
#   end
# end



#------------------------------------------------------------------------------#
#                                                             Function: Update #
#------------------------------------------------------------------------------#
# function update!(obj::OnlineStat{SummaryStatistic}, newdata::Vector)
#   b::Int = length(newdata)
#   obj.n += b

#   if obj.statistic == "mean"
#     obj.estimate += (mean(newdata) - obj.estimate) * b / obj.n

#   elseif obj.statistic == "var, mean"
#     mnew = mean(newdata)
#     obj.estimate = (((obj.n - b - 1)*obj.estimate[1] +
#                       vecnorm(newdata - mnew)^2 +
#                       (obj.n - b) * b / obj.n *
#                       (mnew - obj.estimate[2])^2)/ (obj.n - 1),
#                     obj.estimate[2] + (mnew - obj.estimate[2]) * b / obj.n)

#   else obj.statistic == "quantile-S"
#     r::Int = obj.estimate[2]
#     tau::Float64 = obj.estimate[3]
#     obj.estimate = (obj.estimate[1] -= (mean(newdata < obj.estimate[1]) - tau) /
#                       b,
#                     tau,
#                     r)

#   end
#   obj.nBatch += 1
# end


#------------------------------------------------------------------------------#
#                                                       Function: SummaryTrace #
#------------------------------------------------------------------------------#
# function summaryTrace(y::Vector, b::Int = 1)
#   n::Int = length(y)
#   nIters::Int = convert(Int, round(n/b, 0))
#   results::DataFrame = DataFrame(nUsed = [1:nIters] * b,
#                                  mean = zeros(nIters),
#                                  var = zeros(nIters))

#   # First batch estimates
#   mean_obj::OnlineStat{SummaryStatistic} = oMean(y[1:b])


#   # Collect first batch results
#   results[1, 2] = mean_obj.estimate

#   for i in 2:nIters
#     newvals = [1:b] + (i - 1) * b
#     ynew = y[newvals]

#     # mean
#     update!(mean_obj, ynew)


#     # collect results
#     results[i, 2] = mean_obj.estimate
#   end

#   return results
# end



#------------------------------------------------------------------------------#
#                                                          Interactive Testing #
#------------------------------------------------------------------------------#
# x1 = rand(10)
# obj = oMean(x1)
# x2 = rand(11)
# update!(obj, x2)

# y = rand(100)
# res = summaryTrace(y, 10)
