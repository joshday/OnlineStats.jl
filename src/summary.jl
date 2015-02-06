# This script implements online functions for summary statistics
#
# Each statistic generally has three functions associated with it
#  oStatistic:  First batch run
#  update:      (method) Update oStatistic object with new batch
#  statTrace:   (method) Get trace results for multiple batches
#
# Author: Josh Day <emailjoshday@gmail.com>

export oMean, update!

#------------------------------------------------------------------------------#
#                                                                         Mean #
#------------------------------------------------------------------------------#

#' @@name oMean
#'
#' @@description
#'
#' The first batch run for online mean estimate
function oMean(x::Vector)
  return OnlineStat("mean", mean(x), length(x))
end

function update!(obj::OnlineStat, data::Vector; mean::Bool = true)
  if obj.statistic == "mean"
    b::Int = length(data)
    obj.estimate = obj.estimate  - (b / (b + obj.n)) * (mean(data) - obj.estimate)
    obj.n += b
  else
    warn("wrong statistic specified")
  end
end


















###############################################################################
# methodless update! function
function update!(obj::OnlineStat, data::Array)
  if obj.statistic == "mean"
    update!(obj, data; mean = true)
  else
    warn("not implemented")
  end
end
