# This script implements online functions for summary statistics
#
# Each statistic generally has three functions associated with it
#  oStatistic:  First batch run
#  update:      (method) Update oStatistic object with new batch
#  statTrace:   (method) Get trace results for multiple batches
#
# Author: Josh Day <emailjoshday@gmail.com>

export oMean, update!

###############################################################################
# Mean
@doc meta("First batch calculation for online mean", returns = OnlineStat) ->
function oMean(x::Vector)
  return OnlineStat("mean", mean(x), length(x))
end

@doc "Update an online mean object created from oMean()" ->
function update!(obj::OnlineStat, data::Vector; mean::Bool = true)
  b::Int = length(data)
  obj.estimate = obj.estimate * obj.n / (obj.n + b) + sum(data) / (obj.n + b)
  obj.n += b
end

@doc "Get trace results for online update of mean" ->
function meanTrace(data::Vector, b::Int)

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
