"""
    ZScoreDetector(lag::Int, threshold::T, influence::T, T = Float64) where

Applies the *robust peak detection [...] using z-scores* algorithm to the incoming datastream. 


# Source
    Brakel, J.P.G. van (2014). "Robust peak detection algorithm using z-scores". Stack Overflow. 
    Available at: https://stackoverflow.com/questions/22583391/peak-signal-detection-in-realtime-timeseries-data/22640362#22640362 
    (version: 2020-11-08).

# Example
    o = ZScoreDetector(30,3.0,0.5)
    fit!(o, 1:12)
    o.signal # signal at last observation
"""
mutable struct ZScoreDetector{T} <: OnlineStat{Number}
    n::Int
    lag::Int
    threshold::T
    influence::T
    center::T
    stds::T
    signal::Int
    filtered::CircBuff{T}
end

function ZScoreDetector(lag, threshold, influence, T=Float64)
    @assert threshold > 0 "Threshold needs to be positive."
    @assert lag >= 1 "Lag needs to be >=1"
    ZScoreDetector{T}(0, lag, threshold, influence, 0, 0, 0, CircBuff(T, lag, rev=false))
end

Base.length(o::ZScoreDetector) = o.n
nobs(o::ZScoreDetector) = o.n
value(o::ZScoreDetector) = o.signal

function _fit!(o::ZScoreDetector{T}, y::Real) where {T}
    y = convert(T, y)
    n = o.n + 1
    if n < o.lag
        o.signal = 0
        fit!(o.filtered, y)
    else
        if abs(y - o.center) > o.threshold * o.stds
            y > o.center ? (o.signal = 1) : (o.signal = -1)
            fit!(o.filtered, o.influence * y + (1 - o.influence) * o.filtered[end])
        else
            o.signal = 0
            fit!(o.filtered, y)
        end
        o.center = mean(o.filtered.value)
        o.stds = std(o.filtered.value)
    end
    o.n += 1
end