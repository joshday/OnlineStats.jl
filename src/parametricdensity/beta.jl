#------------------------------------------------------# Type and Constructors
type FitBeta <: UnivariateFitDistribution
    d::Distributions.Beta
    stats::Var
    n::Int64
end

function onlinefit{T <: Real}(::Type{Beta}, y::Vector{T})
    warn("FitBeta Uses method of moments, not MLE")
    n::Int64 = length(y)
    stats = Var(y)
    m = mean(stats)
    v = var(stats)
    α = m * (m * (1 - m) / v - 1)
    β = (1 - m) * (m * (1 - m) / v - 1)
    FitBeta(Beta(α, β), stats, n)
end

FitBeta{T <: Real}(y::Vector{T}) = onlinefit(Beta, y)

#---------------------------------------------------------------------# update!
function update!{T<:Real}(obj::FitBeta, newdata::Vector{T})
    update!(obj.stats, newdata)
    m = mean(obj.stats)
    v = var(obj.stats)
    α = m * (m * (1 - m) / v - 1)
    β = (1 - m) * (m * (1 - m) / v - 1)
    obj.d = Beta(α, β)
    obj.n += length(newdata)
end


#-----------------------------------------------------------------------# Base
Base.copy(obj::FitBeta) = FitBeta(obj.d, obj.stats, obj.n)
