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
export online_summary


#------------------------------------------------------------------------------#
#                                                                        Types #
#------------------------------------------------------------------------------#

type Summary
  mean::Vector{Float64}
  var::Vector{Float64}
  max::Vector{Float64}
  min::Vector{Float64}
  quantile::(Array{Float64}, Float64, String)
  n::Vector{Int}
  nb::Vector{Int}
  details::String
end


#------------------------------------------------------------------------------#
#                                         First batch function: online_summary #
#------------------------------------------------------------------------------#

function online_summary(y::Vector{Float64},
                        tau::Vector{Float64} = [.25, .5, .75];
                        learnrate::Float64 = 0.6,
                        quantalg::String = "S")
  # Error Handling
  if any(tau .<= 0) || any(tau .>= 1)
    error("tau values must be in (0, 1)")
  end
  if learnrate <= .5 || learnrate > 1
    error("learnrate must be in (.5, 1]")
  end
  if quantalg != "S" && quantalg != "MM"
    error("quantile algorithm is either S (Robbins-Monro) or
          MM (Majorization-Minimization)")
  end


  Summary([mean(y)],
          [var(y)],
          [maximum(y)],
          [minimum(y)],
          ([quantile(y, tau)], learnrate, quantalg),
          [length(y)],
          [1],
          "Online summary statistics.")
end


#------------------------------------------------------------------------------#
#                                                                      update! #
#------------------------------------------------------------------------------#

function update!(obj::Summary, newdata::Vector, add::Bool = true)
  b::Int = length(newdata)
  new_mean::Float64 = mean(newdata)

  if add
    # n
    push!(obj.n, obj.n[end] + b)

    # nb
    push!(obj.nb, obj.nb[end] + 1)

    # mean
    push!(obj.mean, obj.mean[end] + b / obj.n[end] * (new_mean - obj.mean[end]))

    # var
    push!(obj.var,
          ((obj.n[end - 1] - 1) * obj.var[end] +
            vecnorm(newdata - new_mean)^2 +
            obj.n[end - 1] * b / obj.n[end] * (new_mean - obj.mean[end-1])^2) /
            (obj.n[end] - 1))

    # maximum and minimum
    push!(obj.max, maximum([obj.max[end], newdata]))
    push!(obj.min, minimum([obj.min[end], newdata]))
  else
    # n
    obj.n[end] = obj.n[end] + b

    # nb
    obj.nb[end] = obj.nb[end] + 1

    # mean
    old_mean::Float64 = obj.mean[end]
    obj.mean[end] += b / obj.n[end] * (new_mean - obj.mean[end])

    # var
    obj.var[end] = ((obj.n[end] - b - 1) * obj.var[end] +
      vecnorm(newdata - new_mean)^2 +
      (obj.n[end] - b) * b / obj.n[end] * (new_mean - old_mean)^2) /
      (obj.n[end] - 1)

    # maximum and minimum
    obj.max[end] = maximum([obj.max[end], newdata])
    obj.min[end] = minimum([obj.min[end], newdata])

  end
end


#------------------------------------------------------------------------------#
#                                                                      make_df #
#------------------------------------------------------------------------------#
function make_df(obj::Summary)
  df = DataFrame(mean = obj.mean,
                 var = obj.var,
                 max = obj.max,
                 min = obj.min)
end



#------------------------------------------------------------------------------#
#                                                          Interactive Testing #
#------------------------------------------------------------------------------#

x1 = rand(10)
ob = online_summary(x1)
x2 = rand(11)
update!(ob, x2, false)
x = [x1, x2]

