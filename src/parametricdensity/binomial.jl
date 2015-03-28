export OnlineFitBinomial

#-----------------------------------------------------------------------------#
#------------------------------------------------------# OnlineFitBinomial Type
type OnlineFitBinomial <: DiscreteUnivariateOnlineStat
    d::Distributions.Binomial
    nsuccess::Int64
    n::Int64
    nb::Int64
end


function onlinefit(::Type{Binomial}, ntrials::Int64, y::Vector{Int64})
    n::Int64 = length(y)
    OnlineFitBinomial(fit(Binomial, ntrials, y), sum(y), n, 1)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineFitBinomial, newdata::Vector{Int64})
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
function Base.show(io::IO, obj::OnlineFitBinomial)
    @printf(io, "OnlineFitBinomial\n")
    @printf(io, " * n: %f\n", obj.d.n)
    @printf(io, " * p: %f\n", obj.d.p)
end



#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
# x1 = rand(Binomial(25, .7), 100)
# obj = OnlineStats.onlinefit(Binomial, 25, x1)
# OnlineStats.state(obj)

# x2 = rand(Binomial(25, .7), 100)
# OnlineStats.update!(obj, x2)
# OnlineStats.state(obj)
 
