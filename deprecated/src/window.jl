
"""
Keep enough history for the given lag indices.  Intended for time-series.
Given lag list [0, 2, 10] for series {yₜ}, we care about storing/indexing [yₜ, yₜ₋₂, yₜ₋₁₀]
Note that we must keep all data points from (t) --> (t - iₙ), so data storage scales 
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

# replicates a typical circular buffer
Window{T<:Real}(::Type{T}, sz::Int) = Window(T, sz-1:-1:0)

# ------------------------------

statenames(o::Window) = [:lags, :nobs]
state(o::Window) = Any[lags(o), nobs(o)]

lags{T}(o::Window{T}) = T[x for x in o]
Base.convert(::Type{Array}, o::Window) = lags(o)

function update!{T<:Real}(o::Window{T}, x::Real)
    push!(o.buf, convert(T, x))
    o.n += 1
    return
end

function Base.empty!{T<:Real}(o::Window{T})
    o.buf = CircularBuffer(T, maximum(o.lagIndices)+1)
    o.n = 0
    return
end

# ------------------------------

_bufferIndex(o::Window, i::Int) = length(o.buf) - o.lagIndices[i]
bufferIndex(o::Window, i::Int) = (i < 1 || i > length(o)) ? error("Idx $i out of range. ", o) : _bufferIndex(o, i)


Base.getindex(o::Window, i::Int) = o.buf[bufferIndex(o, i)]
Base.unsafe_getindex(o::Window, i::Int) = o.buf[_bufferIndex(o, i)]

function Base.setindex!{T}(o::Window, data::T, i::Int)
  o.buf[bufferIndex(o, i)] = data
  nothing
end
function Base.unsafe_setindex!{T}(o::Window, data::T, i::Int)
  o.buf[_bufferIndex(o, i)] = data
  nothing
end

# iteration
Base.start(o::Window) = 1
Base.done(o::Window, state::Int) = state > length(o)
Base.next(o::Window, state::Int) = (o[state], state+1)

# note: length is 0 until the underlying buffer is full
Base.length(o::Window) = (isfull(o) ? capacity(o) : 0)
Base.size(o::Window) = (length(o),)

QuickStructs.capacity(o::Window) = length(o.lagIndices)
QuickStructs.isfull(o::Window) = isfull(o.buf)

# Base.push!{T}(o::Window{T}, data::T) = push!(o.buf, data)
# Base.append!{T}(o::Window{T}, datavec::AbstractVector{T}) = append!(o.buf, datavec)


