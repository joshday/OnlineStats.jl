# Author: Josh Day <emailjoshday@gmail.com>

export QuantileSGD, QuantileMM


#------------------------------------------------------------------------------#
#---------------------------------------------------------------# Quantile Types
### SGD
type QuantileSGD <: ContinuousUnivariateOnlineStat
  est::Matrix{Float64}              # Quantiles
  τs::Vector{Float64}               # tau values
  r::Float64                        # learning rate
  n::Vector{Int64}                  # number of observations used
  nb::Vector{Int64}                 # number of batches used
end

@doc doc"""
Create QuantileSGD object

fields:

  - `est::Matrix`: quantile results

  - `τs::Vector`:  quantiles estimated

  - `r::Float64`:  learning rate

  - `n::Vector`:   number of observations used

  - `nb::Vector`:  number of batches used
""" ->
QuantileSGD(y::Vector; τs::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.51) =
  QuantileSGD(quantile(y, τs)', τs, r, [length(y)], [1])




### MM
type QuantileMM <: ContinuousUnivariateOnlineStat
  est::Matrix{Float64}              # Quantiles
  τs::Vector{Float64}               # tau values
  r::Float64                        # learning rate
  s::Vector{Float64}                # sufficients stats for MM (s, t, and o)
  t::Vector{Float64}
  o::Float64
  n::Vector{Int64}                  # number of observations used
  nb::Vector{Int64}                 # number of batches used
end

@doc doc"""
Create QuantileMM object

fields:

  - `est::Matrix`: quantile results

  - `τs::Vector`:  quantiles estimated

  - `r::Float64`:  learning rate

  - `s::Vector, t::Vector, and o::Float`:  sufficient statistics

  - `n::Vector`:   number of observations used

  - `nb::Vector`:  number of batches used
""" ->
function QuantileMM(y::Vector; τs::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.51)
  p::Int = length(τs)
  qs::Vector = quantile(y, τs) + .00000001
  s::Vector = [sum(abs(y - qs[i]) .^ -1 .* y) for i in 1:p]
  t::Vector = [sum(abs(y - qs[i]) .^ -1) for i in 1:p]
  o::Float64 = length(y)
  qs = [(s[i] + o * (2 * τs[i] - 1)) / t[i] for i in 1:p]

  QuantileMM(qs', τs, r, s, t, o, [length(y)], [1])
end





#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
### SGD
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



### MM
function update!(obj::QuantileMM, newdata::Vector, addrow::Bool = false)
  τs::Vector = obj.τs
  qs::Vector = [i for i in obj.est[end, :]]
  γ::Float64 = obj.nb[end] ^ - obj.r

  for i in 1:length(τs)
    w::Vector = abs(newdata - qs[i]) .^ -1
    obj.s[i] += γ * (sum(w .* newdata) - obj.s[i])
    obj.t[i] += γ * (sum(w) - obj.t[i])
    obj.o += γ * (length(newdata) - obj.o)
    qs[i] = (obj.s[i] + obj.o * (2 * obj.τs[i] - 1)) / obj.t[i]
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



#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::QuantileSGD)
  println(join(("τs = ", obj.τs)))
  println(join(("qs ' ", obj.est[end, :])))
  println(join(("n = ", obj.n[end])))
  println(join(("nb = ", obj.nb[end])))
end

function state(obj::QuantileMM)
  println(join(("τs = ", obj.τs)))
  println(join(("qs ' ", obj.est[end, :])))
  println(join(("n = ", obj.n[end])))
  println(join(("nb = ", obj.nb[end])))
end



#------------------------------------------------------------------------------#
#----------------------------------------------------------------# Base.convert
function Base.convert(::Type{DataFrames.DataFrame}, obj::QuantileSGD)
  df = convert(DataFrames.DataFrame, obj.est)

  # Hack to get correct column names
  τnames = ["q" * string(convert(Int, obj.τs[i] * 100)) for i in 1:length(obj.τs)]
  τnames = convert(Array{Symbol, 1}, τnames)
  names!(df, τnames)

  df[:n] = obj.n
  df[:nb] = obj.nb
  return df
end

function Base.convert(::Type{DataFrames.DataFrame}, obj::QuantileMM)
  df = convert(DataFrames.DataFrame, obj.est)

  # Hack to get correct column names
  τnames = ["q" * string(convert(Int, obj.τs[i] * 100)) for i in 1:length(obj.τs)]
  τnames = convert(Array{Symbol, 1}, τnames)
  names!(df, τnames)

  df[:n] = obj.n
  df[:nb] = obj.nb
  return df
end



#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing

# y1 = rand(111)
# y2 = rand(222)
# y3 = rand(333)

# obj = OnlineStats.QuantileMM(y1, τs = [.1, .2, .4])
# y2 = rand(100)
# OnlineStats.update!(obj, y2, false)
# OnlineStats.update!(obj, y3, true)

# OnlineStats.state(obj)

# println(convert(DataFrame, obj))

