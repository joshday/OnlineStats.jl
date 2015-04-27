#-------------------------------------------------------# Type and Constructors
type FitBernoulli <: UnivariateFitDistribution
    d::Distributions.Bernoulli
    n1::Int64
    n::Int64
end

function onlinefit{T <: Integer}(::Type{Bernoulli}, y::Vector{T})
    n::Int64 = length(y)
    FitBernoulli(fit(Bernoulli, y), sum(y), n)
end

FitBernoulli{T <: Integer}(y::Vector{T}) = onlinefit(Bernoulli, y)

#---------------------------------------------------------------------# update!
function update!{T <: Integer}(obj::FitBernoulli, newdata::Vector{T})
    obj.n1 += sum(newdata)
    obj.n += length(newdata)
    obj.d = Bernoulli(obj.n1 / obj.n)
end


#------------------------------------------------------------------------# Base
function Base.copy(obj::FitBernoulli)
    FitBernoulli(obj.d, obj.n1, obj.n)
end
