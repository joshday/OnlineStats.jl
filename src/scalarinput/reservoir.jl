"""
```julia
ReservoirSample(k)
ReservoirSample(k, Float64)
```
Reservoir sample of `k` items.
### Example
```julia
o = ReservoirSample(k, Int)
s = Series(o)
fit!(s, 1:10000)
```
"""
mutable struct ReservoirSample{T<:Number} <: OnlineStat{0, 1, EqualWeight}
    value::Vector{T}
    nobs::Int
end
ReservoirSample{T<:Number}(k::Integer, ::Type{T} = Float64) = ReservoirSample(zeros(T, k), 0)

function fit!(o::ReservoirSample, y::ScalarOb, γ::Float64)
    o.nobs += 1
    if o.nobs <= length(o.value)
        o.value[o.nobs] = y
    else
        j = rand(1:o.nobs)
        if j < length(o.value)
            o.value[j] = y
        end
    end
end
