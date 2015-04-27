#------------------------------------------------------# Type and Constructors
type FitBinomial <: UnivariateFitDistribution
    d::Distributions.Binomial
    nsuccess::Int64
    n::Int64
end

function onlinefit{T <: Integer}(::Type{Binomial}, y::Vector{T}; ntrials = 1)
    n::Int64 = length(y)
    FitBinomial(fit(Binomial, ntrials, y), sum(y), n)
end

FitBinomial{T <: Integer}(y::Vector{T}; ntrials = 1) =
    onlinefit(Binomial, y, ntrials = ntrials)


#---------------------------------------------------------------------# update!
function update!{T <: Integer}(obj::FitBinomial, newdata::Vector{T})
    obj.nsuccess += sum(newdata)
    obj.n += length(newdata)
    obj.d = Binomial(obj.d.n, obj.nsuccess / (obj.n * obj.d.n))
end


#-----------------------------------------------------------------------# Base
function Base.copy(obj::FitBinomial)
    FitBinomial(obj.d, obj.nsuccess, obj.n)
end
