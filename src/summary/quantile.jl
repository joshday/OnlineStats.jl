# Author: Josh Day <emailjoshday@gmail.com>
#------------------------------------------------------------------------------#
#                                                                      Exports #
#------------------------------------------------------------------------------#
export QuantileSGD, QuantileMM


#------------------------------------------------------------------------------#
#                                                               Quantile Types #
#------------------------------------------------------------------------------#
type QuantileSGD
  est::Matrix{Float64}              # Quantiles
  τs::Vector{Float64}               # tau values
  r::Float64                        # learning rate
  n::Int64                          # number of observations used
  nb::Int64                         # number of batches used
end

QuantileSGD(y::Vector, τs::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.51) =
  QuantileSGD(quantile(y, τs)', τs, r, length(y), 1)

type QuantileMM
  est::Matrix{Float64}              # Quantiles
  τs::Vector{Float64}               # tau values
  r::Float64                        # learning rate
  s::Vector{Float64}                # sufficients stats for MM (s, t, and o)
  t::Vector{Float64}
  o::Float64
  n::Int64                          # number of observations used
  nb::Int64                         # number of batches used
end

function QuantileMM(y::Vector, τs::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.51)
  p::Int = length(τs)
  s::Vector = [sum(abs(y - τs[i]) .^ -1 .* y) for i in 1:p]
  t::Vector = [sum(abs(y - τs[i]) .^ -1) for i in 1:p]
  o::Float64 = length(y)
  qs::Vector = [(s[i] + o * (2 * τs[i] - 1)) / t[i] for i in 1:p]

  QuantileMM(qs', τs, r, s, t, o, length(y), 1)
end


#------------------------------------------------------------------------------#
#                                                                      update! #
#------------------------------------------------------------------------------#
function update!(obj::QuantileSGD, newdata::Vector, addrow::Bool = false)
  τs::Vector = obj.τs
  qs::Vector = [i for i in obj.est[end, :]]
  γ::Float64 = obj.nb ^ - obj.r

  for i in 1:length(τs)
    qs[i] -= γ * (mean(newdata .< qs[i]) - τs[i])
  end

  if addrow
    obj.est = [obj.est, qs']
  else
    obj.est[end, :] = qs'
  end

  obj.n += length(newdata)
  obj.nb += 1
end


#------------------------------------------------------------------------------#
#                                                                        state #
#------------------------------------------------------------------------------#
function state(obj::QuantileSGD)
end

function state(obj::QuantileMM)
end

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
