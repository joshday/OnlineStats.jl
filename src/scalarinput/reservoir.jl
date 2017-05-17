mutable struct ReservoirSample{T<:Number} <: OnlineStat{0, 1}
    value::Vector{T}
    nobs::Int
end
ReservoirSample{T<:Number}(k::Integer, ::Type{T} = Float64) = ReservoirSample(zeros(T, k), 0)

function fit!(o::ReservoirSample, y::Singleton, γ::Float64)
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
