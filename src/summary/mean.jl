#-------------------------------------------------------# Type and Constructors
type Mean <: ScalarStat
    mean::Float64
    n::Int64
end

Mean{T <: Real}(y::Vector{T}) = Mean(mean(y), length(y))

Mean{T <: Real}(y::T) = Mean([y])

Mean() = Mean(0.0, 0)


#-------------------------------------------------------------# param and value
param(obj::Mean) = :μ

value(obj::Mean) = obj.mean


#--------------------------------------------------------------------# update!
function update!{T <: Real}(obj::Mean, y::Vector{T})
    n2 = length(y)
    obj.n += n2
    obj.mean += (n2 / obj.n) * (mean(y) - obj.mean)
end

function update!{T <: Real}(obj::Mean, y::T)
    obj.mean += (1 / obj.n) * (y - obj.mean)
end


#----------------------------------------------------------------------# Base
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
