export OnlineFitBinomial

#-----------------------------------------------------------------------------#
#------------------------------------------------------# OnlineFitBinomial Type
type OnlineFitBinomial <: DiscreteUnivariateOnlineStat
    d::Distributions.Binomial
    nsuccess::Int64
    n::Int64
    nb::Int64
end


function onlinefit{T <: Integer}(::Type{Binomial}, ntrials::Int64, y::Vector{T})
    n::Int64 = length(y)
    OnlineFitBinomial(fit(Binomial, ntrials, y), sum(y), n, 1)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T <: Integer}(obj::OnlineFitBinomial, newdata::Vector{T})
    obj.nsuccess += sum(newdata)
    obj.n += length(newdata)
    obj.d = Binomial(obj.d.n, obj.nsuccess / (obj.n * obj.d.n))
    obj.nb += 1
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitBinomial)
    names = [:ntrials, :p, :n, :nb]
    estimates = [obj.d.n, obj.d.p, obj.n, obj.nb]
    return([names estimates])
end


#----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# Base
function Base.copy(obj::OnlineFitBinomial)
    OnlineFitBinomial(obj.d, obj.nsuccess, obj.n, obj.nb)
end

function Base.show(io::IO, obj::OnlineFitBinomial)
    @printf(io, "OnlineFit (nobs = %i)\n", obj.n)
    show(obj.d)
end

