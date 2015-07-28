
"""
Keep enough history for the given lag indices.  Intended for time-series.
Given lag list [0, 2, 10] for series {yₜ}, we care about storing/indexing [yₜ, yₜ₋₂, yₜ₋₁₀]
Note that we must keep all data points from (t - i₁) --> (t - iₙ), so data storage scales 
with the largest lag.
"""
type Window{T <: Real, VECI <: AVec{Int}} <: OnlineStat
    buf::CircularBuffer{T}
    lagIndices::VECI
    n::Int
end

function Window{T<:Real}(::Type{T}, lagIndices::AVec{Int})
    @assert minimum(lagIndices) >= 0
    Window(CircularBuffer(T, maximum(lagIndices)+1), lagIndices, 0)
end

statenames(o::Window) = [:lags, :nobs]
state(o::Window) = Any[lags(o), nobs(o)]

lags{T,V}(o::Window{T,V}) = T[]

function update!{T<:FloatingPoint}(o::Window{T}, x::Real)
    v = convert(T, x)
    o.diff = (o.n == 0 ? zero(T) : v - last(o))
    o.lastval = v
    o.n += 1
    return
end

function update!{T<:Integer}(o::Window{T}, x::Real)
    v = round(T, x)
    o.diff = (o.n == 0 ? zero(T) : v - last(o))
    o.lastval = v
    o.n += 1
    return
end

function Base.empty!{T<:Real}(o::Window{T})
    o.diff = zero(T)
    o.lastval = zero(T)
    o.n = 0
    return
end



#----------------------
# TODO: merge above and below properly!

function bufferIndex(window::RollingWindow, i::Int)
  if i < 1 || i > length(window)
    error("RollingWindow out of range. window=$window i=$i")
  end
  length(window.cb) - window.lags[i]
end

Base.getindex(window::RollingWindow, i::Int) = window.cb[bufferIndex(window, i)]
function Base.setindex!{T}(window::RollingWindow, data::T, i::Int)
  window.cb[bufferIndex(window, i)] = data
  nothing
end


# note: length is 0 until the underlying buffer is full
Base.length(window::RollingWindow) = (isfull(window) ? capacity(window) : 0)
Base.size(window::RollingWindow) = (length(window),)

capacity(window::RollingWindow) = length(window.lags)
isfull(window::RollingWindow) = isfull(window.cb)
toarray{T}(window::RollingWindow{T}) = window[1:length(window)]

Base.push!{T}(window::RollingWindow{T}, data::T) = push!(window.cb, data)
Base.append!{T}(window::RollingWindow{T}, datavec::AbstractVector{T}) = append!(window.cb, datavec)


