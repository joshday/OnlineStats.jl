export OnlineFitBernoulli

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type OnlineFitBernoulli <: DiscreteUnivariateOnlineStat
    d::Distributions.Bernoulli
    n1::Int64
    n::Int64
    nb::Int64
end

function onlinefit{T <: Integer}(::Type{Bernoulli}, y::Vector{T})
    n::Int64 = length(y)
    OnlineFitBernoulli(fit(Bernoulli, y), sum(y), n, 1)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T <: Integer}(obj::OnlineFitBernoulli, newdata::Vector{T})
    obj.n1 += sum(newdata)
    obj.n += length(newdata)
    obj.d = Bernoulli(obj.n1 / obj.n)
    obj.nb += 1
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitBernoulli)
    names = [:p, :n, :nb]
    estimates = [obj.d.p, obj.n, obj.nb]
    return([names estimates])
end


#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
function Base.copy(obj::OnlineFitBernoulli)
    OnlineFitBernoulli(obj.d, obj.n1, obj.n, obj.nb)
end

function Base.show(io::IO, obj::OnlineFitBernoulli)
    @printf(io, "OnlineFit (nobs = %i)\n", obj.n)
    show(obj.d)
end

Base.mean(obj::OnlineFitBernoulli) = mean(obj.d)
