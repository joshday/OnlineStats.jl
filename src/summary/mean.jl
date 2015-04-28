#-------------------------------------------------------# Type and Constructors
type Mean{W <: Weighting} <: ScalarStat
    mean::Float64
    n::Int64
    weighting::W
end

function Mean{T <: Real}(y::Vector{T}, wgt::Weighting = DEFAULT_WEIGHTING)
    obj = Mean(wgt)
    update!(obj, y)
    obj
end

Mean(y::Float64, wgt::Weighting = DEFAULT_WEIGHTING) = Mean([y], wgt)

Mean(wgt::Weighting = DEFAULT_WEIGHTING) = Mean(0., 0, wgt)

#-----------------------------------------------------------------------# state
state_names(obj::Mean) = [:μ]
state(obj::Mean) = [mean(obj)]


#---------------------------------------------------------------------# update!
function update!(obj::Mean, y::Float64)
    n = nobs(obj)
    λ = weight(obj)

    obj.mean = smooth(obj.mean, y, λ)
    obj.n += 1
    return
end

function update!(obj::Mean, y::Vector)
    for yi in y
        update!(obj, yi)
    end
end


#------------------------------------------------------------------------# Base
Base.copy(obj::Mean) = Mean(obj.mean, obj.n)

Base.mean(obj::Mean) = obj.mean

function Base.merge(a::Mean, b::Mean)
    m = a.mean + (b.n / (a.n + b.n)) * (b.mean - a.mean)
    n = a.n + b.n
    return Mean(m, n)
end

function Base.merge!(a::Mean, b::Mean)
    a.mean += (b.n / (a.n + b.n)) * (b.mean - a.mean)
    a.n += b.n
end
