# Author: Josh Day <emailjoshday@gmail.com>

export QuantileSGD, QuantileMM

#------------------------------------------------------------------------------#
#---------------------------------------------------------------# Quantile Types
@doc "Stores quantile estimates using a stochastic gradient descent algorithm" ->
type QuantileSGD
  est::Matrix{Float64}              # Quantiles
  τs::Vector{Float64}               # tau values
  r::Float64                        # learning rate
  n::Vector{Int64}                  # number of observations used
  nb::Vector{Int64}                 # number of batches used
end

@doc "Consturct QuantileSGD from Vector" ->
QuantileSGD(y::Vector, τs::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.51) =
  QuantileSGD(quantile(y, τs)', τs, r, [length(y)], [1])


@doc "Stores quantile estimating using an online MM algorithm" ->
type QuantileMM
  est::Matrix{Float64}              # Quantiles
  τs::Vector{Float64}               # tau values
  r::Float64                        # learning rate
  s::Vector{Float64}                # sufficients stats for MM (s, t, and o)
  t::Vector{Float64}
  o::Float64
  n::Vector{Int64}                  # number of observations used
  nb::Vector{Int64}                 # number of batches used
end

@doc "Construct QuantileMM from Vector" ->
function QuantileMM(y::Vector, τs::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.51)
  p::Int = length(τs)
  qs::Vector = quantile(y, τs)
  s::Vector = [sum(abs(y - qs[i]) .^ -1 .* y) for i in 1:p]
  t::Vector = [sum(abs(y - qs[i]) .^ -1) for i in 1:p]
  o::Float64 = length(y)
  qs = [(s[i] + o * (2 * τs[i] - 1)) / t[i] for i in 1:p]

  QuantileMM(qs', τs, r, s, t, o, [length(y)], [1])
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
@doc "Update quantile estimates using a new batch of data" ->
function update!(obj::QuantileSGD, newdata::Vector, addrow::Bool = false)
  τs::Vector = obj.τs
  qs::Vector = [i for i in obj.est[end, :]]
  γ::Float64 = obj.nb[end] ^ - obj.r

  for i in 1:length(τs)
    qs[i] -= γ * (mean(newdata .< qs[i]) - τs[i])
  end

  if addrow
    obj.est = [obj.est, qs']
    push!(obj.n, obj.n[end] + length(newdata))
    push!(obj.nb, obj.nb[end] + 1)
  else
    obj.est[end, :] = qs'
    obj.n[end] = obj.n[end] + length(newdata)
    obj.nb[end] += 1
  end
end


@doc "Update quantile estimates using a new batch of data" ->
function update!(obj::QuantileMM, newdata::Vector, addrow::Bool = false)
  τs::Vector = obj.τs
  qs::Vector = [i for i in obj.est[end, :]]
  γ::Float64 = obj.nb[end] ^ - obj.r

  for i in 1:length(τs)
    w::Vector = abs(newdata - qs[i]) .^ -1
    obj.s[i] += γ * (sum(w .* newdata) - obj.s[i])
    obj.t[i] += γ * (sum(w) - obj.t[i])
    obj.o += γ * (length(newdata) - obj.o)
    qs[i] = (s[i] + o * (t * τs[i] - 1)) / t[i]
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
#-----------------------------------------------------------------------# state
function state(obj::QuantileSGD)
  println(join(("τs = ", obj.τs)))
  println(join(("qs ' ", obj.est[end, :])))
  println(join(("n = ", obj.n[end])))
  println(join(("nb = ", obj.nb[end])))
end

function state(obj::QuantileMM)
end


#------------------------------------------------------------------------------#
#----------------------------------------------------------------# Base.convert
@doc "Convert 'obj' to type 'DataFrame'" ->
function Base.convert(::Type{DataFrames.DataFrame}, obj::QuantileSGD)
  df = convert(DataFrames.DataFrame, obj.est)
  df[:n] = obj.n
  df[:nb] = obj.nb
  return df
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing

y1 = rand(111)
y2 = rand(222)
y3 = rand(333)

obj = OnlineStats.QuantileSGD(y1)
OnlineStats.update!(obj, y2, false)
OnlineStats.update!(obj, y3, true)

OnlineStats.state(obj)

convert(DataFrame, obj)

