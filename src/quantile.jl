

#------------------------------------------------------------------------------#
#                                                                Quantile Type #
#------------------------------------------------------------------------------#
type Quantile
  est::Matrix{Float64}              # Quantiles
  tau::Vector{Float64}              # tau values
  r::Float64                        # learning rate
  alg::String                       # algorithm - S or MM
  sto::(Float64, Float64, Float64)  # sufficients stats for MM
  n::Int64                          # number of observations used
  nb::Int64                         # number of batches used
end


#------------------------------------------------------------------------------#
#                                                                      update! #
#------------------------------------------------------------------------------#
function update!(obj::Quantile, newdata::Vector, addrow::Bool)


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
