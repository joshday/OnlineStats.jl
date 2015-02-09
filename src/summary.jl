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
# export Summary
# export online_summary, quantile_update!, update!, make_df, state


#------------------------------------------------------------------------------#
#                                                                        Types #
#------------------------------------------------------------------------------#
type Quantile
  est::Matrix{Float64}  # Quantiles
  tau::Vector{Float64}  # tau values
  r::Float64             # learning rate
  alg::String           # Algorithm - S or MM
  sto::(Float64, Float64, Float64)  # sufficients stats for MM
end


type Summary
  mean::Vector{Float64}
  var::Vector{Float64}
  max::Vector{Float64}
  min::Vector{Float64}
  quantile::Quantile
  n::Vector{Int}
  nb::Vector{Int}
  details::String
end


#------------------------------------------------------------------------------#
#                                         First batch function: online_summary #
#------------------------------------------------------------------------------#

function online_summary(y::Vector{Float64};
                        tau::Vector{Float64} = [.25, .5, .75],
                        learnrate::Float64 = 0.51,
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
          Quantile([quantile(y, tau)'], tau, learnrate, quantalg,
                   (0.0, 0.0, 0.0)),
          [length(y)],
          [1],
          "Online summary statistics.")
end


#------------------------------------------------------------------------------#
#                                                                       update #
#------------------------------------------------------------------------------#

#---------------------------------------------------------#
#                                         quantile_update #
#---------------------------------------------------------#
function quantile_update!(obj::Summary, addrow::Bool, newdata::Vector)
  τs::Vector{Float64} = obj.quantile.tau
  qs::Matrix{Float64} = obj.quantile.est[end, :]
  p::Int = length(τs)
  iter::Int = obj.nb[end]
  γ::Float64 = iter ^ - obj.quantile.r

  if obj.quantile.alg == "S"
    for j in 1:p
      qs[1, j] -= γ * (mean(newdata .< qs[1, j]) - τs[j])
    end
  end

  if obj.quantile.alg == "MM"
    for j in 1:p
      q::Float64 = qs[1, j]
      τ::Float64 = τs[j]
      w::Vector{Float64} = abs(newdata - q) .^ -1
      sumw::Float64 = sum(w)
      sumyw::Float64 = sum(w .* newdata)
      s,t,o = obj.quantile.sto
      s += γ * (sumyw - s)
      t += γ * (sumw - t)
      o += γ * (length(newdata) - o)
      qs[1, j] =  (s + o * (2 * τ - 1)) / t
      obj.quantile.sto = s,t,o
    end
  end

  if addrow
      obj.quantile.est = [obj.quantile.est, qs]
    else
      obj.quantile.est[end, :] = qs
    end

end

#---------------------------------------------------------#
#                                                 update! #
#---------------------------------------------------------#

function update!(obj::Summary, newdata::Vector, addrow::Bool = true)
  n1::Int = obj.n[end]
  n2::Int = length(newdata)
  n::Int = n1 + n2

  μ1::Float64 = obj.mean[end]
  μ2::Float64 = mean(newdata)
  δ::Float64 = μ2 - μ1

  ss1::Float64 = (n1 - 1) * obj.var[end]
  ss2::Float64 = vecnorm(newdata - μ2) ^ 2

  if addrow
    # n
    push!(obj.n, n)

    # nb
    push!(obj.nb, obj.nb[end] + 1)

    # mean
    push!(obj.mean, μ1 + n2 / n * δ)

    # var
    push!(obj.var, (ss1 + ss2 + n1 * n2 / n * δ^2) / (n - 1))

    # maximum and minimum
    push!(obj.max, maximum([obj.max[end], newdata]))
    push!(obj.min, minimum([obj.min[end], newdata]))

    # Quantiles
    quantile_update!(obj, true, newdata)

  else
    # n
    obj.n[end] = n

    # nb
    obj.nb[end] = obj.nb[end] + 1

    # mean
    obj.mean[end] = μ1 + n2 / n * δ

    # var
    obj.var[end] = (ss1 + ss2 + n1 * n2 / n * δ^2) / (n - 1)

    # maximum and minimum
    obj.max[end] = maximum([obj.max[end], newdata])
    obj.min[end] = minimum([obj.min[end], newdata])

    # quantiles
    quantile_update!(obj, false, newdata) # Still needs to be implemented
  end
end


#------------------------------------------------------------------------------#
#                                                                      make_df #
#------------------------------------------------------------------------------#
function make_df(obj::Summary)
  df = DataFrames.DataFrame()
  df[:mean] = obj.mean
  df[:var] = obj.var
  df[:max] = obj.max
  df[:min] = obj.min

  # Quantile df
  qdf = convert(DataFrame, obj.quantile.est)
  if obj.quantile.tau == [0.25, 0.5, 0.75]
    names!(qdf, [:q25, :q50, :q75])
  end
  df = [df qdf]

  df[:n] = obj.n
  df[:nb] = obj.nb
  return df
end


#------------------------------------------------------------------------------#
#                                                                       state #
#------------------------------------------------------------------------------#

function state(obj::Summary)
  println(join(("mean = ", obj.mean[end])))
  println(join(("var = ", obj.var[end])))
  println(join(("max = ", obj.max[end])))
  println(join(("min = ", obj.min[end])))

  # for i in taus...print quantile
  j::Int = 1
  for i in obj.quantile.tau
    println(join(("q", convert(Int, i*100), " = ", obj.quantile.est[end, j])))
    j += 1
  end

  println(join(("n = ", obj.n[end])))
  println(join(("nb = ", obj.nb[end])))
end

#------------------------------------------------------------------------------#
#                                                          Interactive Testing #
#------------------------------------------------------------------------------#

# x1 = rand(10)
# ob = online_summary(x1)
# x2 = rand(11)
# update!(ob, x2, false)

# x3 = rand(12)
# update!(ob, x3, true)

# make_df(ob)

