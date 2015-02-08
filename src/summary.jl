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
export Summary
export online_mean


#------------------------------------------------------------------------------#
#                                                                        Types #
#------------------------------------------------------------------------------#

type Summary
  mean::Vector{Float64}
  var::Vector{Float64}
  max::Vector{Float64}
  min::Vector{Float64}
  quantile::(Array{Float64}, Float64)
  n::Vector{Int}
  nb::Vector{Int}
  details
end

#------------------------------------------------------------------------------#
#                                                        First Batch Functions #
#------------------------------------------------------------------------------#
#----------------------------------------------------------#
#                                           online_summary #
#----------------------------------------------------------#

function online_summary(y::Vector{Float64},
                        tau::Vector{Float64} = [.25, .5, .75];
                        learnrate::Float64 = 0.6)

 Summary([mean(y)],
         [var(y)],
         [maximum(y)],
         [minimum(y)],
         ([quantile(y, tau)], learnrate),
         [length(y)],
         [1],
         "")
end




#------------------------------------------------------------------------------#
#                                                          Interactive Testing #
#------------------------------------------------------------------------------#

x1 = rand(10)
ob = online_summary(x1)


